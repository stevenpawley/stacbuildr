# stacbuildr vs pystac comparison harness — Python (pystac) side.
#
# Companion to dev/compare-with-pystac.R. The R script runs its own scenarios,
# writes r_results.json plus fixture files into a data dir, then invokes this
# script with the pystac-enabled interpreter. This script mirrors the R
# scenarios one-for-one (keep the scenario names in sync with the R file!) and
# writes py_results.json for the R script to diff.
#
# Usage:
#   python compare-with-pystac.py --data-dir <dir> --r-out <dir> --out <dir>
import argparse, json, os, datetime, subprocess
import pystac
from pystac.utils import str_to_datetime
from pystac.extensions.projection import ProjectionExtension, AssetProjectionExtension
from pystac.extensions.classification import ClassificationExtension, AssetClassificationExtension, Classification, Bitfield
from pystac.extensions.datacube import DatacubeExtension, HorizontalSpatialDimension, TemporalDimension, Variable
from pystac.extensions.table import TableExtension, AssetTableExtension, Column
from pystac.extensions.scientific import ScientificExtension, Publication
from pystac.extensions.render import RenderExtension, Render
import pystac.extensions.eo as eo_mod
import pystac.extensions.raster as ra_mod
import pystac.extensions.pointcloud as pc_mod

_parser = argparse.ArgumentParser()
_parser.add_argument("--data-dir", required=True, help="dir with fixture files written by the R side (boundary.geojson, multi_geom.json, test.tif, scene.tif, wgs84.tif, roundtrip_item.json)")
_parser.add_argument("--r-out", required=True, help="dir with files written by the R side (single_catalog.json)")
_parser.add_argument("--out", required=True, help="dir for py_results.json and the pystac-written catalog trees")
_args = _parser.parse_args()
OUT_DIR = _args.out
DATA_DIR = _args.data_dir
R_OUT = _args.r_out

# Extension schema URIs targeted by stacbuildr (from its registry)
EO_V2 = "https://stac-extensions.github.io/eo/v2.0.0/schema.json"
RASTER_V2 = "https://stac-extensions.github.io/raster/v2.0.0/schema.json"
PC_V2 = "https://stac-extensions.github.io/pointcloud/v2.0.0/schema.json"
VECTOR_V01 = "https://stac-extensions.github.io/vector/v0.1.0/schema.json"
DC_V23 = "https://stac-extensions.github.io/datacube/v2.3.0/schema.json"

def dt(s):
    return str_to_datetime(s) if s else None

def mk_point_item(id="observation-001", **kw):
    return pystac.Item(id=id,
                       geometry={"type": "Point", "coordinates": [-105.0, 40.0]},
                       bbox=[-105.0, 40.0, -105.0, 40.0],
                       datetime=dt("2023-06-15T10:30:00Z"),
                       properties=kw.pop("properties", {}), **kw)

def mk_polygon_item(id="LC08_L1TP_044034_20230615"):
    return pystac.Item(
        id=id,
        geometry={"type": "Polygon", "coordinates": [[[-105.5, 39.5], [-104.5, 39.5], [-104.5, 40.5], [-105.5, 40.5], [-105.5, 39.5]]]},
        bbox=[-105.5, 39.5, -104.5, 40.5],
        datetime=dt("2023-06-15T17:30:00Z"),
        properties={"title": "Landsat 8 Scene", "platform": "landsat-8",
                    "instruments": ["oli", "tirs"], "gsd": 30, "eo:cloud_cover": 5.2})

def mk_extent():
    return pystac.Extent(
        spatial=pystac.SpatialExtent([[-180, -90, 180, 90], [-120, 30, -110, 40]]),
        temporal=pystac.TemporalExtent([[dt("2020-01-01T00:00:00Z"), dt("2020-12-31T23:59:59Z")],
                                         [dt("2021-01-01T00:00:00Z"), None]]))

def mk_extent_3d():
    return pystac.Extent(
        spatial=pystac.SpatialExtent([[-105.5, 39.5, 100, -104.5, 40.5, 2500]]),
        temporal=pystac.TemporalExtent([[dt("2020-01-01T00:00:00Z"), dt("2020-12-31T23:59:59Z")]]))

def mk_collection(id="sentinel-2-l2a"):
    return pystac.Collection(
        id=id, description="Sentinel-2 Level-2A BOA reflectance products.",
        extent=mk_extent(), license="CC-BY-4.0", title="Sentinel-2 Level-2A",
        keywords=["sentinel", "esa", "msi"],
        providers=[pystac.Provider(name="ESA", description="European Space Agency",
                                   roles=[pystac.ProviderRole.PRODUCER, pystac.ProviderRole.LICENSOR],
                                   url="https://earth.esa.int/web/guest/home")],
        summaries=pystac.Summaries({
            "platform": ["sentinel-2a", "sentinel-2b"],
            "gsd": {"minimum": 10, "maximum": 60},
            "bands": [{"name": "B01", "eo:common_name": "coastal"},
                      {"name": "B02", "eo:common_name": "blue"}]}))

# --- v2-style band dict builders (pystac 1.14.3 has no eo/raster v2 support) ---
def eo_band_v2(name=None, common_name=None, description=None, center_wavelength=None,
               full_width_half_max=None, solar_illumination=None, **extra):
    d = {}
    if name is not None: d["name"] = name
    if description is not None: d["description"] = description
    if common_name is not None: d["eo:common_name"] = common_name
    if center_wavelength is not None: d["eo:center_wavelength"] = center_wavelength
    if full_width_half_max is not None: d["eo:full_width_half_max"] = full_width_half_max
    if solar_illumination is not None: d["eo:solar_illumination"] = solar_illumination
    d.update(extra)
    return d

def raster_band_v2(nodata=None, data_type=None, unit=None, statistics=None, sampling=None,
                   bits_per_sample=None, spatial_resolution=None, scale=1, offset=0,
                   histogram=None, **extra):
    d = {}
    if nodata is not None: d["nodata"] = nodata
    if data_type is not None: d["data_type"] = data_type
    if unit is not None: d["unit"] = unit
    if statistics is not None: d["statistics"] = statistics
    if sampling is not None: d["raster:sampling"] = sampling
    if bits_per_sample is not None: d["raster:bits_per_sample"] = bits_per_sample
    if spatial_resolution is not None: d["raster:spatial_resolution"] = spatial_resolution
    if scale is not None: d["raster:scale"] = scale
    if offset is not None: d["raster:offset"] = offset
    if histogram is not None: d["raster:histogram"] = histogram
    d.update(extra)
    return d

def add_ext(item, uri):
    if uri not in item.stac_extensions:
        item.stac_extensions.append(uri)
    return item

scenarios = {}

# ---- core ---------------------------------------------------------------------
scenarios["stac_catalog_min"] = lambda: pystac.Catalog(id="my-catalog", description="A catalog of satellite imagery")

def _stac_catalog_full():
    c = pystac.Catalog(id="versioned-catalog", title="Versioned Catalog",
                       description="A catalog with version tracking",
                       stac_extensions=["https://stac-extensions.github.io/version/v1.2.0/schema.json"],
                       extra_fields={"conformsTo": ["https://stacspec.org/api/conformance"],
                                     "version": "1.0.0", "deprecated": False})
    c.add_link(pystac.Link("self", "https://example.com/catalog.json", media_type="application/json"))
    return c
scenarios["stac_catalog_full"] = _stac_catalog_full

def _stac_link_full():
    return pystac.Link("related", "https://example.com/metadata.html", media_type="text/html",
                       title="Additional metadata",
                       extra_fields={"method": "POST", "body": {"a": 1}, "x-custom": "yes"})
scenarios["stac_link_full"] = _stac_link_full

def _add_link_catalog():
    c = pystac.Catalog(id="my-catalog", description="Example catalog")
    c.add_link(pystac.Link("self", "https://example.com/catalog.json", media_type="application/json"))
    c.add_link(pystac.Link("related", "https://example.com/metadata.html", media_type="text/html", title="Additional metadata"))
    return c
scenarios["add_link_catalog"] = _add_link_catalog

def _add_self_root():
    c = pystac.Catalog(id="my-catalog", description="Example catalog")
    c.add_link(pystac.Link("self", "https://example.com/catalog.json", media_type="application/json"))
    c.add_link(pystac.Link("root", "https://example.com/catalog.json", media_type="application/json", title="Root catalog"))
    return c
scenarios["add_self_link_root_link"] = _add_self_root

def _add_child_catalog():
    parent = pystac.Catalog(id="parent-catalog", description="Parent catalog", title="Parent")
    child = pystac.Catalog(id="landsat", description="Landsat satellite imagery", title="Landsat Imagery")
    parent.add_link(pystac.Link("child", "./landsat/catalog.json", media_type="application/json", title="Landsat Imagery"))
    return parent
scenarios["add_child_catalog"] = _add_child_catalog

def _add_child_collection():
    parent = pystac.Catalog(id="parent-catalog", description="Parent catalog")
    col = mk_collection("sentinel-2-l2a")
    parent.add_link(pystac.Link("child", "./sentinel-2-l2a/collection.json", media_type="application/json", title=col.title))
    return parent
scenarios["add_child_collection"] = _add_child_collection

def _stac_collection_min():
    return pystac.Collection(id="landsat-8-c2-l2",
                             description="Landsat 8 Collection 2 Level-2 Surface Reflectance",
                             license="CC0-1.0",
                             extent=pystac.Extent(spatial=pystac.SpatialExtent([[-180, -90, 180, 90]]),
                                                  temporal=pystac.TemporalExtent([[dt("2013-04-11T00:00:00Z"), None]])))
scenarios["stac_collection_min"] = _stac_collection_min

def _stac_collection_full():
    col = mk_collection()
    col.add_link(pystac.Link("self", "https://example.com/collections/sentinel-2-l2a.json", media_type="application/json"))
    col.add_link(pystac.Link("root", "https://example.com/catalog.json", media_type="application/json"))
    col.add_link(pystac.Link("license", "https://creativecommons.org/licenses/by/4.0/", media_type="text/html", title="CC-BY-4.0"))
    col.add_asset("thumbnail", pystac.Asset(href="https://example.com/thumb.png", title="Thumbnail",
                                             media_type="image/png", roles=["thumbnail"]))
    return col
scenarios["stac_collection_full"] = _stac_collection_full

def _stac_collection_ext():
    return pystac.Collection(id="col-ext", description="Collection with extensions", license="other",
                             extent=mk_extent(),
                             stac_extensions=["https://stac-extensions.github.io/render/v2.0.0/schema.json"],
                             extra_fields={"conformsTo": ["https://stacspec.org/api/conformance"], "custom_field": {"a": 1}})
scenarios["stac_collection_ext_conforms"] = _stac_collection_ext

scenarios["stac_extent"] = mk_extent
scenarios["stac_extent_3d"] = mk_extent_3d

scenarios["stac_provider_full"] = lambda: pystac.Provider(
    name="USGS", description="United States Geological Survey",
    roles=[pystac.ProviderRole.PRODUCER, pystac.ProviderRole.LICENSOR, pystac.ProviderRole.HOST],
    url="https://www.usgs.gov")
scenarios["stac_provider_min"] = lambda: pystac.Provider(name="ESA")

def _stac_summaries():
    s = pystac.Summaries({"platform": ["landsat-8", "landsat-9"], "instruments": ["oli"],
                          "gsd": {"minimum": 15, "maximum": 30},
                          "bands": [{"name": "B1", "eo:common_name": "coastal"}],
                          "single": ["one-value"]})
    return s.to_dict()
scenarios["stac_summaries"] = _stac_summaries

scenarios["stac_item_point_min"] = mk_point_item
scenarios["stac_item_polygon_props"] = mk_polygon_item

def _stac_item_timerange():
    return pystac.Item(id="composite-2023-q2",
                       geometry={"type": "Polygon", "coordinates": [[[-180, -90], [180, -90], [180, 90], [-180, 90], [-180, -90]]]},
                       bbox=[-180, -90, 180, 90], datetime=None,
                       properties={"title": "Q2 2023 Global Composite",
                                   "start_datetime": "2023-04-01T00:00:00Z",
                                   "end_datetime": "2023-06-30T23:59:59Z"})
scenarios["stac_item_timerange"] = _stac_item_timerange

def _stac_item_3d():
    return pystac.Item(id="lidar-001", geometry={"type": "Point", "coordinates": [-105.0, 40.0, 1500.0]},
                       bbox=[-105.0, 40.0, 1500.0, -105.0, 40.0, 1500.0],
                       datetime=dt("2023-06-15T14:00:00Z"), properties={})
scenarios["stac_item_3d"] = _stac_item_3d

def _stac_item_nonspatial():
    return pystac.Item(id="global-report-2023", geometry=None, bbox=None,
                       datetime=dt("2023-12-31T23:59:59Z"),
                       properties={"title": "Annual Global Climate Report"})
scenarios["stac_item_nonspatial"] = _stac_item_nonspatial

def _stac_item_ext_collection():
    return pystac.Item(id="item-ext", geometry={"type": "Point", "coordinates": [-105.0, 40.0]},
                       bbox=[-105.0, 40.0, -105.0, 40.0], datetime=dt("2023-06-15T10:30:00Z"),
                       properties={}, collection="sentinel-2-l2a", stac_extensions=[EO_V2])
scenarios["stac_item_ext_collection"] = _stac_item_ext_collection

scenarios["stac_asset_full"] = lambda: pystac.Asset(
    href="./data/LC08_B4.tif", title="Band 4 - Red", description="Red band reflectance",
    media_type="image/tiff; application=geotiff", roles=["data", "reflectance"],
    extra_fields={"bands": [{"name": "B4", "eo:common_name": "red"}]})
scenarios["stac_asset_min"] = lambda: pystac.Asset(href="https://example.com/image.tif")

def _add_asset_item():
    item = mk_point_item()
    item.add_asset("visual", pystac.Asset(href="https://example.com/LC08_visual.tif", title="True Color Image",
                                          media_type="image/tiff; application=geotiff", roles=["visual"]))
    item.add_asset("thumbnail", pystac.Asset(href="https://example.com/LC08_thumb.png", title="Thumbnail",
                                             media_type="image/png", roles=["thumbnail"]))
    return item
scenarios["add_asset_item"] = _add_asset_item

scenarios["stac_geometry_point"] = lambda: {"type": "Point", "coordinates": [-105, 40]}
scenarios["stac_geometry_polygon"] = lambda: {"type": "Polygon", "coordinates": [[[-105.5, 39.5], [-104.5, 39.5], [-104.5, 40.5], [-105.5, 40.5], [-105.5, 39.5]]]}
scenarios["stac_geometry_collection"] = lambda: {"type": "GeometryCollection", "geometries": [
    {"type": "Point", "coordinates": [-105, 40]},
    {"type": "LineString", "coordinates": [[-105, 40], [-104, 41]]}]}

def _add_item_collection():
    col = mk_collection()
    col.add_link(pystac.Link("self", "https://example.com/collections/sentinel-2-l2a.json", media_type="application/json"))
    col.add_link(pystac.Link("root", "https://example.com/catalog.json", media_type="application/json"))
    item = mk_point_item("item-001", properties={"title": "First item"})
    col.add_link(pystac.Link("item", "./item-001/item-001.json", media_type="application/geo+json", title="First item"))
    item.collection_id = col.id
    # append directly: pystac's add_link tries to resolve root/parent/collection hrefs to objects
    item.links.append(pystac.Link("parent", "https://example.com/collections/sentinel-2-l2a.json", media_type="application/json"))
    item.links.append(pystac.Link("root", "https://example.com/catalog.json", media_type="application/json"))
    item.links.append(pystac.Link("collection", "https://example.com/collections/sentinel-2-l2a.json", media_type="application/json"))
    return {"collection": col.to_dict(), "stored_item": item.to_dict()}
scenarios["add_item_collection"] = _add_item_collection

def _add_item_catalog_default_href():
    cat = pystac.Catalog(id="cat", description="d")
    item = mk_point_item("item-001")
    cat.add_link(pystac.Link("item", "./item-001/item-001.json", media_type="application/geo+json"))
    return {"collection": cat.to_dict(), "stored_item": item.to_dict()}
scenarios["add_item_catalog_default_href"] = _add_item_catalog_default_href

def _extent_from_items():
    i1 = pystac.Item(id="i1", geometry={"type": "Point", "coordinates": [-105.0, 40.0]}, bbox=[-105.0, 40.0, -105.0, 40.0],
                     datetime=dt("2023-06-01T00:00:00Z"), properties={})
    i2 = pystac.Item(id="i2", geometry={"type": "Point", "coordinates": [-100, 45]}, bbox=[-100, 45, -100, 45],
                     datetime=dt("2023-07-01T00:00:00Z"), properties={})
    i3 = pystac.Item(id="i3", geometry=None, bbox=None, datetime=dt("2023-08-01T00:00:00Z"), properties={})
    items = [i1, i2, i3]
    bboxes = [it.bbox for it in items if it.bbox is not None]
    overall = [min(b[0] for b in bboxes), min(b[1] for b in bboxes), max(b[2] for b in bboxes), max(b[3] for b in bboxes)]
    from pystac.utils import datetime_to_str
    dts = []
    for it in items:
        if it.datetime is not None:
            dts.append(datetime_to_str(it.datetime))
        elif it.properties.get("datetime"):
            dts.append(it.properties["datetime"])
        if it.properties.get("start_datetime"): dts.append(it.properties["start_datetime"])
        if it.properties.get("end_datetime"): dts.append(it.properties["end_datetime"])
    start, end = min(dts), max(dts)
    if start == end: end = None
    return pystac.Extent(spatial=pystac.SpatialExtent([overall]),
                         temporal=pystac.TemporalExtent([[dt(start), dt(end) if end else None]])).to_dict()
scenarios["extent_from_items"] = _extent_from_items

def _get_item_links():
    cat = pystac.Catalog(id="cat", description="d")
    cat.add_link(pystac.Link("item", "./item-001/item-001.json", media_type="application/geo+json"))
    cat.add_link(pystac.Link("item", "./item-002/item-002.json", media_type="application/geo+json"))
    return [l.to_dict() for l in cat.links if l.rel == "item"]
scenarios["get_item_links"] = _get_item_links

def _get_items_get_children():
    root = pystac.Catalog(id="cat", description="d")
    child = pystac.Catalog(id="child-1", description="c")
    root.add_child(child)
    root.add_item(mk_point_item("item-001"))
    return {"items": [i.to_dict() for i in root.get_items()],
            "children": [c.to_dict() for c in root.get_children()]}
scenarios["get_items_get_children"] = _get_items_get_children

def _count_items():
    cat = pystac.Catalog(id="cat", description="d")
    cat.add_link(pystac.Link("item", "./item-001/item-001.json", media_type="application/geo+json"))
    cat.add_link(pystac.Link("item", "./item-002/item-002.json", media_type="application/geo+json"))
    return sum(1 for l in cat.links if l.rel == "item")
scenarios["count_items"] = _count_items

def _remove_item():
    cat = pystac.Catalog(id="cat", description="d")
    cat.add_link(pystac.Link("item", "./item-001/item-001.json", media_type="application/geo+json"))
    cat.add_link(pystac.Link("item", "./item-002/item-002.json", media_type="application/geo+json"))
    cat.links = [l for l in cat.links if not (l.rel == "item" and os.path.splitext(os.path.basename(l.href))[0] == "item-001")]
    return cat.to_dict()
scenarios["remove_item"] = _remove_item

def _add_item_assets():
    col = mk_collection()
    item = mk_point_item("item-001")
    asset = pystac.Asset(href="red.tif", title="Red Band", media_type="image/tiff", roles=["data"])
    asset.extra_fields["bands"] = [eo_band_v2(name="B4", common_name="red")]
    item.add_asset("red", asset)
    col.add_link(pystac.Link("item", "./item-001/item-001.json", media_type="application/geo+json"))
    # item_assets definition = asset fields minus href, statistics dropped from bands
    col.extra_fields["item_assets"] = {"red": {"title": "Red Band", "type": "image/tiff", "roles": ["data"],
                                               "bands": [{"name": "B4", "eo:common_name": "red"}]}}
    return col.to_dict()
scenarios["add_item_assets"] = _add_item_assets

# ---- EO extension (v2 manual; pystac native v1.1.0 recorded separately) --------
scenarios["eo_band_min"] = lambda: eo_band_v2(name="B4", common_name="red")
scenarios["eo_band_full"] = lambda: eo_band_v2(name="B2", common_name="blue", description="Blue band (0.45-0.51)",
                                                center_wavelength=0.490, full_width_half_max=0.065, solar_illumination=1959.66)

def _add_eo_cloud():
    item = mk_point_item()
    add_ext(item, EO_V2)
    item.properties["eo:cloud_cover"] = 12.5
    item.properties["eo:snow_cover"] = 3.1
    return item
scenarios["add_eo_extension_cloud"] = _add_eo_cloud

def _add_eo_bands_props():
    item = mk_point_item()
    add_ext(item, EO_V2)
    item.properties["eo:cloud_cover"] = 5.2
    item.properties["bands"] = [
        eo_band_v2(name="B4", common_name="red", center_wavelength=0.665, full_width_half_max=0.038),
        eo_band_v2(name="B3", common_name="green", center_wavelength=0.560, full_width_half_max=0.043)]
    return item
scenarios["add_eo_extension_bands_props"] = _add_eo_bands_props

def _add_eo_bands_asset():
    item = mk_point_item()
    item.add_asset("visual", pystac.Asset(href="https://example.com/LC08_visual.tif",
                                          media_type="image/tiff; application=geotiff", roles=["data"]))
    add_ext(item, EO_V2)
    item.properties["eo:cloud_cover"] = 5.2
    item.assets["visual"].extra_fields["bands"] = [
        eo_band_v2(name="B4", common_name="red", center_wavelength=0.665, full_width_half_max=0.038),
        eo_band_v2(name="B3", common_name="green", center_wavelength=0.560, full_width_half_max=0.043),
        eo_band_v2(name="B2", common_name="blue", center_wavelength=0.490, full_width_half_max=0.038)]
    return item
scenarios["add_eo_extension_bands_asset"] = _add_eo_bands_asset

def _landsat():
    data = [("B1", "coastal", 0.44, 0.02), ("B2", "blue", 0.48, 0.06), ("B3", "green", 0.56, 0.06),
            ("B4", "red", 0.655, 0.04), ("B5", "nir", 0.865, 0.03), ("B6", "swir16", 1.61, 0.08),
            ("B7", "swir22", 2.2, 0.18), ("B8", "pan", 0.59, 0.18), ("B9", "cirrus", 1.37, 0.02),
            ("B10", "lwir11", 10.895, 0.59), ("B11", "lwir12", 12.005, 1.01)]
    return [eo_band_v2(name=n, common_name=c, center_wavelength=w, full_width_half_max=f) for n, c, w, f in data]
scenarios["eo_bands_landsat_oli"] = _landsat

def _sentinel2():
    data = [("B01", "coastal", 0.443, 0.02), ("B02", "blue", 0.493, 0.065), ("B03", "green", 0.559, 0.035),
            ("B04", "red", 0.665, 0.031), ("B05", "rededge071", 0.704, 0.015), ("B06", "rededge075", 0.740, 0.014),
            ("B07", "rededge078", 0.781, 0.019), ("B08", "nir", 0.833, 0.105), ("B8A", "nir08", 0.864, 0.021),
            ("B09", "nir09", 0.944, 0.020), ("B10", "cirrus", 1.375, 0.029), ("B11", "swir16", 1.612, 0.092),
            ("B12", "swir22", 2.194, 0.179)]
    return [eo_band_v2(name=n, common_name=c, center_wavelength=w, full_width_half_max=f) for n, c, w, f in data]
scenarios["eo_bands_sentinel2"] = _sentinel2

def _worldview3():
    data = [("PAN", "pan", 0.625, 0.350), ("B01", "coastal", 0.425, 0.050), ("B02", "blue", 0.480, 0.060),
            ("B03", "green", 0.545, 0.070), ("B04", "yellow", 0.605, 0.040), ("B05", "red", 0.660, 0.060),
            ("B06", "rededge", 0.725, 0.040), ("B07", "nir01", 0.833, 0.125), ("B08", "nir02", 0.950, 0.180),
            ("B09", "swir01", 1.210, 0.030), ("B10", "swir02", 1.570, 0.040), ("B11", "swir03", 1.660, 0.040),
            ("B12", "swir04", 1.730, 0.040), ("B13", "swir05", 2.165, 0.040), ("B14", "swir06", 2.205, 0.040),
            ("B15", "swir07", 2.260, 0.050), ("B16", "swir08", 2.330, 0.070)]
    return [eo_band_v2(name=n, common_name=c, center_wavelength=w, full_width_half_max=f) for n, c, w, f in data]
scenarios["eo_bands_worldview3"] = _worldview3

def _skysat():
    data = [("B01", "blue", 0.4825, 0.065), ("B02", "green", 0.555, 0.08), ("B03", "red", 0.65, 0.09),
            ("B04", "nir", 0.77, 0.06), ("PAN", "pan", 0.675, 0.45)]
    return [eo_band_v2(name=n, common_name=c, center_wavelength=w, full_width_half_max=f) for n, c, w, f in data]
scenarios["eo_bands_skysat"] = _skysat

def _planetscope():
    data = [("B01", "coastal", 0.443, 0.02), ("B02", "blue", 0.49, 0.05), ("B03", "green1", 0.531, 0.036),
            ("B04", "green", 0.565, 0.036), ("B05", "yellow", 0.61, 0.02), ("B06", "red", 0.665, 0.031),
            ("B07", "rededge", 0.705, 0.015), ("B08", "nir", 0.865, 0.04)]
    return [eo_band_v2(name=n, common_name=c, center_wavelength=w, full_width_half_max=f) for n, c, w, f in data]
scenarios["eo_bands_planetscope"] = _planetscope

# native pystac eo v1.1.0 for contrast
def _add_eo_bands_asset_native():
    item = mk_point_item()
    item.add_asset("visual", pystac.Asset(href="https://example.com/LC08_visual.tif",
                                          media_type="image/tiff; application=geotiff", roles=["data"]))
    e = eo_mod.AssetEOExtension.ext(item.assets["visual"], add_if_missing=True)
    e.apply(bands=[eo_mod.Band.create(name="B4", common_name="red", center_wavelength=0.665, full_width_half_max=0.038),
                   eo_mod.Band.create(name="B3", common_name="green", center_wavelength=0.560, full_width_half_max=0.043),
                   eo_mod.Band.create(name="B2", common_name="blue", center_wavelength=0.490, full_width_half_max=0.038)])
    ie = eo_mod.ItemEOExtension.ext(item, add_if_missing=True)
    ie.cloud_cover = 5.2
    return item
scenarios["add_eo_extension_bands_asset_native"] = _add_eo_bands_asset_native

# ---- Raster extension (v2 manual; native v1.1.0 recorded separately) -----------
def _raster_band_full():
    return raster_band_v2(
        nodata=0, data_type="uint16", unit="1",
        statistics={"minimum": 1, "maximum": 10000, "mean": 2500, "stddev": 1200, "valid_percent": 99.5},
        sampling="area", bits_per_sample=16, spatial_resolution=30, scale=0.0001, offset=-0.1,
        histogram={"count": 5, "min": 0, "max": 100, "buckets": [1500, 3200, 4100, 2800, 1400]})
scenarios["raster_band_full"] = _raster_band_full
scenarios["raster_band_defaults"] = lambda: raster_band_v2()
scenarios["raster_statistics"] = lambda: {"minimum": 0, "maximum": 10000, "mean": 2500, "stddev": 1200, "valid_percent": 99.8}
scenarios["raster_histogram"] = lambda: {"count": 5, "min": 0, "max": 100, "buckets": [1500, 3200, 4100, 2800, 1400]}

def _add_raster_asset():
    item = mk_point_item()
    item.add_asset("data", pystac.Asset(href="https://example.com/image.tif",
                                        media_type="image/tiff; application=geotiff", roles=["data"]))
    add_ext(item, RASTER_V2)
    item.assets["data"].extra_fields["bands"] = [
        raster_band_v2(nodata=0, data_type="uint16", spatial_resolution=10, scale=0.0001, offset=-0.1,
                       statistics={"minimum": 1, "maximum": 10000, "mean": 2500, "stddev": 1200, "valid_percent": 99.5}),
        raster_band_v2(nodata=0, data_type="uint16", spatial_resolution=10, scale=0.0001, offset=-0.1)]
    return item
scenarios["add_raster_extension_asset"] = _add_raster_asset

def _add_raster_props():
    item = mk_point_item()
    item.add_asset("data", pystac.Asset(href="https://example.com/image.tif",
                                        media_type="image/tiff; application=geotiff", roles=["data"]))
    add_ext(item, RASTER_V2)
    item.assets["data"].extra_fields["bands"] = [raster_band_v2(nodata=0, data_type="uint16", spatial_resolution=30, scale=0.0001)]
    item.properties["bands"] = [raster_band_v2(data_type="uint16")]
    return item
scenarios["add_raster_extension_props"] = _add_raster_props

def _add_eo_raster_merged():
    item = mk_point_item()
    item.add_asset("visual", pystac.Asset(href="https://example.com/v.tif",
                                          media_type="image/tiff; application=geotiff", roles=["data"]))
    add_ext(item, EO_V2)
    add_ext(item, RASTER_V2)
    item.properties["eo:cloud_cover"] = 5.2
    merged = eo_band_v2(name="B4", common_name="red", center_wavelength=0.665, full_width_half_max=0.038,
                        description="Red band (0.64-0.67)")
    merged.update(raster_band_v2(nodata=0, data_type="uint16", spatial_resolution=30, scale=0.0001))
    item.assets["visual"].extra_fields["bands"] = [merged]
    return item
scenarios["add_eo_and_raster_merged"] = _add_eo_raster_merged

def _raster_native():
    item = mk_point_item()
    item.add_asset("data", pystac.Asset(href="https://example.com/image.tif",
                                        media_type="image/tiff; application=geotiff", roles=["data"]))
    e = ra_mod.AssetRasterExtension.ext(item.assets["data"], add_if_missing=True)
    e.apply(bands=[ra_mod.RasterBand.create(
        nodata=0, data_type="uint16", spatial_resolution=10, scale=0.0001, offset=-0.1,
        statistics=ra_mod.Statistics({"minimum": 1, "maximum": 10000, "mean": 2500, "stddev": 1200, "valid_percent": 99.5})),
        ra_mod.RasterBand.create(nodata=0, data_type="uint16", spatial_resolution=10, scale=0.0001, offset=-0.1)])
    return item
scenarios["add_raster_extension_asset_native"] = _raster_native

def _bands_from_terra():
    import rasterio, numpy as np
    f = os.path.join(DATA_DIR, "test.tif")
    with rasterio.open(f) as ds:
        res = (abs(ds.transform.a), abs(ds.transform.e))
        spatial_resolution = sum(res) / len(res)
        bands = []
        for i in range(1, ds.count + 1):
            arr = ds.read(i)
            vals = arr.ravel()
            stats = {"minimum": float(np.min(vals)), "maximum": float(np.max(vals)),
                     "mean": float(np.mean(vals)), "stddev": float(np.std(vals, ddof=1)),
                     "valid_percent": 100.0 * float(np.count_nonzero(~np.isnan(vals))) / float(vals.size)}
            bands.append(raster_band_v2(data_type=str(ds.dtypes[i - 1]), spatial_resolution=spatial_resolution,
                                        statistics=stats))
        return bands
scenarios["bands_from_terra"] = _bands_from_terra

def _read_bands_no_stats():
    import rasterio
    f = os.path.join(DATA_DIR, "test.tif")
    with rasterio.open(f) as ds:
        res = (abs(ds.transform.a), abs(ds.transform.e))
        spatial_resolution = sum(res) / len(res)
        return [raster_band_v2(data_type=str(ds.dtypes[i]), spatial_resolution=spatial_resolution)
                for i in range(ds.count)]
scenarios["band_from_file"] = _read_bands_no_stats


# ---- Projection extension (pystac native v2.0.0) -------------------------------
def _add_proj_full():
    item = mk_point_item("utm-scene")
    e = ProjectionExtension.ext(item, add_if_missing=True)
    e.apply(code="EPSG:32612", wkt2='PROJCRS["WGS 84 / UTM zone 12N"]',
            projjson={"type": "ProjectedCRS", "name": "WGS 84 / UTM zone 12N"},
            geometry={"type": "Polygon", "coordinates": [[[712710, 5487090], [999480, 5487090], [999480, 5654790], [712710, 5654790], [712710, 5487090]]]},
            bbox=[712710, 5487090, 999480, 5654790], centroid={"lat": 51.05, "lon": -114.07},
            shape=[5558, 9559], transform=[30, 0, 712710, 0, -30, 5654790])
    return item
scenarios["add_projection_extension_full"] = _add_proj_full

def _add_proj_asset():
    item = mk_point_item()
    item.add_asset("swir", pystac.Asset(href="https://example.com/swir.tif", media_type="image/tiff; application=geotiff"))
    e = AssetProjectionExtension.ext(item.assets["swir"], add_if_missing=True)
    e.apply(shape=[2779, 4780], transform=[60, 0, 712710, 0, -60, 5654790])
    return item
scenarios["add_projection_extension_asset"] = _add_proj_asset

# ---- Classification extension (pystac native v2.0.0) ---------------------------
scenarios["classification_class_full"] = lambda: Classification({
    "value": 2, "name": "urban", "title": "Urban / Built-up", "description": "Impervious surfaces.",
    "color_hint": "FF0000", "percentage": 12.4, "count": 24800}).to_dict()
scenarios["classification_class_nodata"] = lambda: Classification({"value": 0, "name": "nodata", "nodata": True}).to_dict()

def _classification_bitfield():
    return Bitfield({"offset": 0, "length": 1,
                     "classes": [Classification({"value": 0, "name": "no_fill", "title": "No Fill"}).to_dict(),
                                 Classification({"value": 1, "name": "fill", "title": "Fill"}).to_dict()],
                     "name": "fill", "description": "Image or fill data", "roles": ["data"]}).to_dict()
scenarios["classification_bitfield"] = _classification_bitfield

def _add_classif_classes_asset():
    item = mk_polygon_item("lc-2023")
    item.add_asset("landcover", pystac.Asset(href="https://example.com/lc-2023.tif",
                                             media_type="image/tiff; application=geotiff", roles=["data"]))
    e = AssetClassificationExtension.ext(item.assets["landcover"], add_if_missing=True)
    e.apply(classes=[Classification({"value": 1, "name": "water", "title": "Water", "color_hint": "0000FF"}),
                     Classification({"value": 2, "name": "urban", "title": "Urban", "color_hint": "FF0000"}),
                     Classification({"value": 0, "name": "nodata", "nodata": True})])
    return item
scenarios["add_classification_extension_classes_asset"] = _add_classif_classes_asset

def _add_classif_bitfields_props():
    item = mk_point_item()
    e = ClassificationExtension.ext(item, add_if_missing=True)
    e.apply(bitfields=[Bitfield({"offset": 0, "length": 1,
                                 "classes": [{"value": 0, "name": "no_fill"}, {"value": 1, "name": "fill"}],
                                 "name": "fill", "description": "Image or fill data"})])
    return item
scenarios["add_classification_extension_bitfields_props"] = _add_classif_bitfields_props

# ---- Point cloud extension (v2 manual; native v1.0.0 recorded separately) -------
scenarios["pc_schema"] = lambda: [{"name": "X", "size": 8, "type": "floating"},
                                  {"name": "Intensity", "size": 2, "type": "unsigned"}]
scenarios["pc_statistic"] = lambda: {"name": "Z", "position": 2, "average": 500.1, "count": 10653336,
                                     "maximum": 615.26, "minimum": 406.14, "stddev": 10.5, "variance": 110.25}

def _add_pc_full():
    item = mk_polygon_item("autzen")
    add_ext(item, PC_V2)
    item.properties["pc:count"] = 10653336
    item.properties["pc:type"] = "lidar"
    item.properties["pc:density"] = 4.664
    item.properties["pc:schemas"] = [{"name": "X", "size": 8, "type": "floating"},
                                     {"name": "Y", "size": 8, "type": "floating"},
                                     {"name": "Z", "size": 8, "type": "floating"},
                                     {"name": "Intensity", "size": 2, "type": "unsigned"}]
    item.properties["pc:statistics"] = [{"name": "Z", "position": 2, "minimum": 406.14, "maximum": 615.26}]
    return item
scenarios["add_pointcloud_extension_full"] = _add_pc_full

def _add_pc_asset():
    item = mk_polygon_item("autzen")
    item.add_asset("lidar", pystac.Asset(href="https://example.com/autzen.laz",
                                         media_type="application/vnd.laszip", roles=["data"]))
    add_ext(item, PC_V2)
    item.assets["lidar"].extra_fields["pc:count"] = 10653336
    item.assets["lidar"].extra_fields["pc:type"] = "lidar"
    item.assets["lidar"].extra_fields["pc:schemas"] = [{"name": "X", "size": 8, "type": "floating"}]
    return item
scenarios["add_pointcloud_extension_asset"] = _add_pc_asset

def _add_pc_native():
    item = mk_polygon_item("autzen")
    e = pc_mod.PointcloudExtension.ext(item, add_if_missing=True)
    e.apply(count=10653336, type="lidar", encoding={"type": "laszip"}, density=4.664,
            schemas=[pc_mod.Schema.create(name="X", size=8, type="floating"),
                     pc_mod.Schema.create(name="Y", size=8, type="floating"),
                     pc_mod.Schema.create(name="Z", size=8, type="floating"),
                     pc_mod.Schema.create(name="Intensity", size=2, type="unsigned")],
            statistics=[pc_mod.Statistic.create(name="Z", position=2, minimum=406.14, maximum=615.26)])
    return item
scenarios["add_pointcloud_extension_full_native"] = _add_pc_native

# ---- Datacube extension ---------------------------------------------------------
scenarios["cube_dimension_spatial"] = lambda: {"type": "spatial", "axis": "x", "extent": [0, 100],
                                               "values": [0, 100], "step": 1, "unit": "m",
                                               "reference_system": 32612, "description": "x axis"}
scenarios["cube_dimension_temporal"] = lambda: {"type": "temporal", "extent": ["2020-01-01T00:00:00Z", None],
                                                "values": ["2020-01-01T00:00:00Z"]}
scenarios["cube_dimension_geometry"] = lambda: {"type": "geometry", "axes": ["x", "y"], "bbox": [0, 0, 100, 100],
                                                "geometry_types": ["Point", "Polygon"], "reference_system": 32612,
                                                "description": "footprint"}
scenarios["cube_variable"] = lambda: {"dimensions": ["x", "t"], "type": "data", "extent": [0, 100],
                                      "values": [0, 100], "unit": "m", "nodata": 0, "data_type": "uint16",
                                      "description": "temperature"}

def _add_datacube():
    item = mk_point_item("cube-item")
    e = DatacubeExtension.ext(item, add_if_missing=True)
    # stacbuildr targets v2.3.0; pystac 1.14.3 native is v2.2.0 — patch URI for field comparison
    item.stac_extensions = [DC_V23 if u.endswith("datacube/v2.2.0/schema.json") else u for u in item.stac_extensions]
    e.apply(dimensions={"x": HorizontalSpatialDimension({"type": "spatial", "axis": "x", "extent": [0, 100]}),
                        "t": TemporalDimension({"type": "temporal", "extent": ["2020-01-01T00:00:00Z", None]})},
            variables={"temp": Variable({"type": "data", "dimensions": ["x", "t"], "nodata": -9999, "data_type": "float32"})})
    return item
scenarios["add_datacube_extension"] = _add_datacube

def _add_datacube_asset():
    item = mk_point_item()
    item.add_asset("data", pystac.Asset(href="https://example.com/cube.nc",
                                        media_type="application/x-netcdf", roles=["data"]))
    e = DatacubeExtension.ext(item, add_if_missing=True)
    item.stac_extensions = [DC_V23 if u.endswith("datacube/v2.2.0/schema.json") else u for u in item.stac_extensions]
    ae = __import__("pystac.extensions.datacube", fromlist=["AssetDatacubeExtension"]).AssetDatacubeExtension.ext(item.assets["data"], add_if_missing=True)
    ae.variables = {"temp": Variable({"type": "data", "dimensions": ["x"], "data_type": "float32"})}
    return item
scenarios["add_datacube_extension_asset"] = _add_datacube_asset

# ---- Table extension (pystac native v1.2.0) ------------------------------------
scenarios["table_column"] = lambda: Column({"name": "id", "description": "Identifier", "type": "integer"}).to_dict()

def _add_table_props():
    item = mk_point_item("tbl")
    e = TableExtension.ext(item, add_if_missing=True)
    e.columns = [Column({"name": "id", "description": "Identifier", "type": "integer"}),
                 Column({"name": "value", "type": "float64"})]
    e.primary_geometry = "geometry"
    e.row_count = 100
    return item
scenarios["add_table_extension_props"] = _add_table_props

def _add_table_asset():
    item = mk_point_item()
    item.add_asset("data", pystac.Asset(href="https://example.com/t.parquet",
                                        media_type="application/octet-stream", roles=["data"]))
    e = AssetTableExtension.ext(item.assets["data"], add_if_missing=True)
    e.columns = [Column({"name": "id", "type": "integer"})]
    e.storage_options = {"io": "s3"}
    return item
scenarios["add_table_extension_asset"] = _add_table_asset

# ---- Vector extension (no pystac equivalent; manual via pystac primitives) ------
def _add_vector():
    item = mk_polygon_item("vec")
    add_ext(item, VECTOR_V01)
    item.properties["vector:geometry_types"] = ["Point", "Polygon"]
    item.properties["vector:mmu"] = 1.0
    item.properties["vector:mmw"] = 2.5
    item.properties["vector:reference_scale"] = 1000
    return item
scenarios["add_vector_extension"] = _add_vector

# ---- Render extension (pystac native v2.0.0) -----------------------------------
def _render_object_full():
    return Render({"assets": ["visual"], "title": "RGB", "rescale": [[0, 255]], "nodata": 0,
                   "colormap_name": "viridis", "colormap": {"0": "#000000"}, "color_formula": "x",
                   "resampling": "nearest", "expression": "b1", "minmax_zoom": [10, 14], "bidx": [1]}).to_dict()
scenarios["render_object_full"] = _render_object_full

def _add_render_item():
    item = mk_point_item()
    e = RenderExtension.ext(item, add_if_missing=True)
    e.renders = {"rgb": Render({"assets": ["visual"], "title": "RGB", "rescale": [[0, 255]], "nodata": 0})}
    return item
scenarios["add_render_extension_item"] = _add_render_item

def _add_render_collection():
    col = mk_collection()
    e = RenderExtension.ext(col, add_if_missing=True)
    e.renders = {"rgb": Render({"assets": ["visual"], "colormap_name": "viridis"})}
    return col
scenarios["add_render_extension_collection"] = _add_render_collection

# ---- Scientific extension (pystac native v1.0.0) --------------------------------
scenarios["scientific_publication"] = lambda: Publication(doi="10.1000/abc", citation="A publication citation").to_dict()

def _add_sci_doi():
    item = mk_point_item()
    e = ScientificExtension.ext(item, add_if_missing=True)
    e.apply(doi="10.1000/xyz123")
    return item
scenarios["add_scientific_extension_doi"] = _add_sci_doi

def _add_sci_full():
    item = mk_point_item()
    e = ScientificExtension.ext(item, add_if_missing=True)
    e.apply(doi="10.1000/xyz123", citation="Some citation",
            publications=[Publication(doi="10.1000/abc", citation="Pub citation")])
    return item
scenarios["add_scientific_extension_full"] = _add_sci_full

# ---- sf / terra integrations ----------------------------------------------------
def _geometry_from_sf():
    with open(os.path.join(DATA_DIR, "boundary.geojson")) as f:
        gj = json.load(f)
    return gj["features"][0]["geometry"]
scenarios["geometry_from_sf"] = _geometry_from_sf

def _item_from_sf():
    with open(os.path.join(DATA_DIR, "boundary.geojson")) as f:
        gj = json.load(f)
    geom = gj["features"][0]["geometry"]
    xs = [c[0] for c in geom["coordinates"][0]]
    ys = [c[1] for c in geom["coordinates"][0]]
    bbox = [min(xs), min(ys), max(xs), max(ys)]
    item = pystac.Item(id="study-area", geometry=geom, bbox=bbox, datetime=dt("2023-01-01T00:00:00Z"),
                       properties={"title": "Study Area Boundary"})
    href = os.path.join(DATA_DIR, "boundary.geojson")
    item.add_asset("source", pystac.Asset(href=href, media_type="application/geo+json", roles=["data"]))
    return item
scenarios["item_from_sf"] = _item_from_sf

def _item_from_sf_multi():
    with open(os.path.join(DATA_DIR, "multi_geom.json")) as f:
        geom = json.load(f)
    def coords(g):
        if g["type"] == "GeometryCollection":
            out = []
            for gg in g["geometries"]: out += coords(gg)
            return out
        if g["type"] == "MultiPolygon":
            return [c for poly in g["coordinates"] for ring in poly for c in ring]
        if g["type"] == "Polygon":
            return [c for ring in g["coordinates"] for c in ring]
        return g["coordinates"]
    cs = coords(geom)
    xs = [c[0] for c in cs]; ys = [c[1] for c in cs]
    bbox = [min(xs), min(ys), max(xs), max(ys)]
    return pystac.Item(id="multi", geometry=geom, bbox=bbox, datetime=dt("2023-01-01T00:00:00Z"), properties={})
scenarios["item_from_sf_multi"] = _item_from_sf_multi
def _item_from_sf_mixed():
    from shapely.geometry import Polygon, Point, mapping
    from shapely.ops import unary_union
    poly = Polygon([(-105.5, 39.5), (-104.5, 39.5), (-104.5, 40.5), (-105.5, 40.5), (-105.5, 39.5)])
    pt = Point(-100, 50)
    geom = mapping(unary_union([poly, pt]))
    def coords(g):
        if g["type"] == "GeometryCollection":
            out = []
            for gg in g["geometries"]: out += coords(gg)
            return out
        if g["type"] in ("Polygon", "MultiPolygon"):
            polys = g["coordinates"] if g["type"] == "MultiPolygon" else [g["coordinates"]]
            return [c for p in polys for ring in p for c in ring]
        return [g["coordinates"]]
    cs = coords(geom)
    bbox = [min(c[0] for c in cs), min(c[1] for c in cs), max(c[0] for c in cs), max(c[1] for c in cs)]
    return pystac.Item(id="mixed", geometry=geom, bbox=bbox, datetime=dt("2023-01-01T00:00:00Z"), properties={})
scenarios["item_from_sf_mixed_geometry"] = _item_from_sf_mixed

def _is_cog(path):
    try:
        import sys
        rio = os.path.join(os.path.dirname(sys.executable), "rio")
        out = subprocess.run([rio, "info", path], capture_output=True, text=True).stdout
        return "LAYOUT=COG" in out
    except Exception:
        return False

def _item_from_terra(wgs84=False):
    import rasterio
    from rasterio.warp import transform
    f = os.path.join(DATA_DIR, "wgs84.tif" if wgs84 else "scene.tif")
    with rasterio.open(f) as ds:
        crs = ds.crs
        b = ds.bounds
        if wgs84:
            xs = [b.left, b.right, b.right, b.left]; ys = [b.bottom, b.bottom, b.top, b.top]
            wgs_geom = {"type": "Polygon", "coordinates": [[[x, y] for x, y in zip(xs, ys)] + [[xs[0], ys[0]]]]}
            bbox = [b.left, b.bottom, b.right, b.top]
        else:
            xs, ys = transform(crs, "EPSG:4326", [b.left, b.right, b.right, b.left], [b.bottom, b.bottom, b.top, b.top])
            wgs_geom = {"type": "Polygon", "coordinates": [[[x, y] for x, y in zip(xs, ys)] + [[xs[0], ys[0]]]]}
            bbox = [min(xs), min(ys), max(xs), max(ys)]
        t = ds.transform
        res = (abs(t.a), abs(t.e))
        spatial_resolution = sum(res) / len(res)
        dt_map = {"uint8": "uint8", "uint16": "uint16", "int16": "int16", "uint32": "uint32",
                  "int32": "int32", "float32": "float32", "float64": "float64"}
        bands = [raster_band_v2(data_type=dt_map[str(ds.dtypes[i])], spatial_resolution=spatial_resolution)
                 for i in range(ds.count)]
        code = None
        if crs.to_epsg() is not None:
            code = "EPSG:%d" % crs.to_epsg()
        wkt2 = crs.to_wkt()
        proj_bbox = [b.left, b.bottom, b.right, b.top]
        shape = [ds.height, ds.width]
        tr = [t.a, t.b, t.c, t.d, t.e, t.f]
        nodata = ds.nodata
        crs_epsg = crs.to_epsg()
    props = {"platform": "landsat-8"} if not wgs84 else {}
    item = pystac.Item(id="wgs84-item" if wgs84 else "scene", geometry=wgs_geom, bbox=bbox,
                       datetime=dt("2023-06-15T10:30:00Z"), properties=props)
    media = "image/tiff; application=geotiff"
    if _is_cog(f):
        media += "; profile=cloud-optimized"
    asset = pystac.Asset(href=os.path.abspath(f), media_type=media, roles=["data"])
    if nodata is not None:
        asset.extra_fields["nodata"] = nodata
    asset.extra_fields["bands"] = bands
    item.add_asset("data", asset)
    add_ext(item, RASTER_V2)
    if not wgs84 and crs_epsg != 4326:
        add_ext(item, "https://stac-extensions.github.io/projection/v2.0.0/schema.json")
        item.properties["proj:code"] = code
        item.properties["proj:wkt2"] = wkt2
        item.properties["proj:bbox"] = proj_bbox
        item.properties["proj:shape"] = shape
        item.properties["proj:transform"] = tr
    return item
scenarios["item_from_terra"] = lambda: _item_from_terra(False)
scenarios["item_from_terra_wgs84"] = lambda: _item_from_terra(True)

def _thumbnail_sf():
    return pystac.Asset(href=os.path.join(DATA_DIR, "thumb_sf.png"), title="Study area thumbnail",
                        media_type="image/png", roles=["thumbnail"])
scenarios["thumbnail_from_sf"] = _thumbnail_sf

def _thumbnail_terra():
    return pystac.Asset(href=os.path.join(DATA_DIR, "thumb_terra.png"),
                        media_type="image/png", roles=["thumbnail"])
scenarios["thumbnail_from_terra"] = _thumbnail_terra
scenarios["preview_from_terra"] = _thumbnail_terra  # deprecated alias of thumbnail_from_terra

# ---- read / write ---------------------------------------------------------------
def _write_read_roundtrip_item():
    # pystac reads the exact file stacbuildr wrote (write_item + read_stac round trip)
    f = os.path.join(DATA_DIR, "roundtrip_item.json")
    return pystac.read_file(f).to_dict()
scenarios["write_read_roundtrip_item"] = _write_read_roundtrip_item

def _read_manifest(out):
    manifest = {}
    for dirpath, _, files in os.walk(out):
        for fn in sorted(files):
            full = os.path.join(dirpath, fn)
            rel = os.path.relpath(full, out)
            with open(full) as fh:
                manifest[rel] = json.load(fh)
    return manifest

def _py_tree_full():
    import shutil
    out = os.path.join(OUT_DIR, "py_out")
    shutil.rmtree(out, ignore_errors=True)
    root = pystac.Catalog(id="root-cat", description="Root catalog", title="Root")
    child = pystac.Catalog(id="child-cat", description="Child catalog")
    col = mk_collection("col-1")
    item = mk_point_item("item-001")
    item.add_asset("data", pystac.Asset(href="https://example.com/data.tif",
                                        media_type="image/tiff; application=geotiff", roles=["data"]))
    col.add_item(item)
    child.add_child(col)
    root.add_child(child)
    root.set_self_href(os.path.join(out, "catalog.json"))
    child.set_self_href(os.path.join(out, "child-cat", "catalog.json"))
    col.set_self_href(os.path.join(out, "child-cat", "col-1", "collection.json"))
    item.set_self_href(os.path.join(out, "child-cat", "col-1", "item-001", "item-001.json"))
    root.save(catalog_type=pystac.CatalogType.SELF_CONTAINED, dest_href=out)
    return _read_manifest(out)
scenarios["write_stac_tree"] = _py_tree_full

def _py_tree_relative():
    import shutil
    out = os.path.join(OUT_DIR, "py_out_rel")
    shutil.rmtree(out, ignore_errors=True)
    base = "https://example.com/stac"
    root = pystac.Catalog(id="root-cat", description="Root catalog")
    item = mk_point_item("item-001")
    root.add_item(item)
    root.set_self_href(base + "/catalog.json")
    item.set_self_href(base + "/item-001/item-001.json")
    root.save(catalog_type=pystac.CatalogType.RELATIVE_PUBLISHED, dest_href=out)
    return _read_manifest(out)
scenarios["write_stac_tree_relative"] = _py_tree_relative

def _write_catalog_file():
    c = pystac.Catalog(id="c", description="d")
    c.set_self_href("https://example.com/c/catalog.json")
    return c.to_dict()
scenarios["write_catalog_file"] = _write_catalog_file

def _read_stac_catalog():
    # pystac reads the exact file stacbuildr wrote with write_catalog
    f = os.path.join(R_OUT, "single_catalog.json")
    return pystac.read_file(f).to_dict()
scenarios["read_stac_catalog"] = _read_stac_catalog

def _write_item_file():
    # stacbuildr write_item writes the object as-is (no self link added)
    return mk_point_item("single").to_dict()
scenarios["write_item_file"] = _write_item_file

# ---- validation -----------------------------------------------------------------
def _validate(obj):
    # pystac validate() raises STACValidationError on failure; returns list of schema URIs on success
    try:
        obj.validate()
        return {"valid": True, "errors": [], "warnings": []}
    except Exception as e:
        return {"valid": False, "errors": [str(e)[:600]], "warnings": []}

scenarios["validate_stac_item_ok"] = lambda: _validate(mk_polygon_item())
def _validate_bad():
    item = mk_point_item("bad")
    item.properties["datetime"] = "not-a-date"
    return _validate(item)
scenarios["validate_stac_item_bad"] = _validate_bad
scenarios["validate_stac_collection_ok"] = lambda: _validate(mk_collection())
scenarios["validate_stac_catalog_ok"] = lambda: _validate(pystac.Catalog(id="c", description="d"))
def _validate_schema_item():
    item = mk_polygon_item()
    add_ext(item, EO_V2)
    item.properties["eo:cloud_cover"] = 5.2
    return _validate(item)
scenarios["validate_stac_schema_item"] = _validate_schema_item
scenarios["validate_stac_schema_collection"] = lambda: _validate(mk_collection())

scenarios["item_from_lidr"] = lambda: {"__error__": "N/A: lidR not installed in R; pystac has no LAS reader in this venv"}
scenarios["items_from_lascatalog"] = lambda: {"__error__": "N/A: lidR not installed in R; pystac has no LAS reader in this venv"}

# ---- run ------------------------------------------------------------------------
results = {}
for name, fn in scenarios.items():
    try:
        obj = fn()
        if hasattr(obj, "to_dict"):
            value = obj.to_dict()
        else:
            value = obj
        results[name] = {"ok": True, "value": value}
        print("%-45s OK" % name)
    except Exception as e:
        results[name] = {"ok": False, "value": {"__error__": "%s: %s" % (type(e).__name__, e)}}
        print("%-45s ERROR: %s" % (name, e))

meta = {"pystac_version": pystac.__version__, "stac_version": pystac.get_stac_version()}
with open(os.path.join(OUT_DIR, "py_results.json"), "w") as fh:
    json.dump({"meta": meta, "results": results}, fh, indent=1)
print("Wrote py_results.json with", len(results), "scenarios")
