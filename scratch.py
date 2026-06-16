import pystac
import datetime

# define item and asset
item = pystac.Item(
    id="observation-001",
    geometry={"type": "Point", "coordinates": [-105.0, 40.0]},
    bbox=[-105.0, 40.0, -105.0, 40.0],
    datetime=datetime.datetime.fromisoformat("2023-06-15T10:30:00Z"),
    properties={},
)

item.to_dict()

asset = pystac.Asset(
    href="https://example.com/image.tif",
    title="RGB Image",
    media_type="image/tiff; application=geotiff",
)

asset.to_dict()

# add raster extension
from pystac.extensions.raster import RasterExtension, RasterBand
from pystac.extensions.raster import Statistics


item.add_asset("test", asset)
raster_ext = RasterExtension.ext(asset, add_if_missing=True)
band = RasterBand.create(
    nodata=0, 
    spatial_resolution=10, 
    sampling="point", 
    bits_per_sample=1,
    statistics=Statistics.create(minimum=0, maximum=0)
)

band.to_dict()

raster_ext.bands = [band]
item.to_dict()

pystac.extensions.raster.Histogram.create(
    count=-1, 
    min=0, 
    max=1, 
    buckets=[0, 1]
)

item.to_dict()

# %% eo extension
from pystac.extensions.eo import EOExtension, Band

eo = EOExtension.ext(item, add_if_missing=True)

eo_band = Band.create("wv3", center_wavelength=0.5)
eo_band.to_dict()

eo.apply(bands=[eo_band])
item.to_dict()




import pystac, datetime
from pystac.extensions.eo import EOExtension, Band

dt = datetime.datetime(2023, 6, 15, 10, 30, 0, tzinfo=datetime.timezone.utc)
py_item = pystac.Item(
    id='ext-test',
    geometry={'type': 'Point', 'coordinates': [-105.0, 40.0]},
    bbox=[-105.0, 40.0, -105.0, 40.0],
    datetime=dt,
    properties={}
)
py_item.add_asset('data', pystac.Asset(
    href='https://example.com/image.tif',
    media_type='image/tiff; application=geotiff'
))

eo = EOExtension.ext(py_item, add_if_missing=True)
eo.apply(
    bands=[
        Band.create(name='B4', common_name='red', center_wavelength=0.665),
        Band.create(name='B3', common_name='green', center_wavelength=0.560),
        Band.create(name='B2', common_name='blue', center_wavelength=0.490),
    ])

py_asset_eo_result = py_item.to_dict()