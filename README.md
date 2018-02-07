# C/C++ DataStax Enterprise Driver Examples

Examples for using the C/C++ DataStax Enterprise driver. The [`dse`](dse)
directory contains examples for DataStax Enterprise specific functionality and
the [`core`](core) includes examples for general functionality.

## Documentation

Driver documentation can be found on our [documentation site].

## To build:

```
mkdir build
cd build
cmake ..
make
```

The following environment/cmake variables may need to be set to the install
location of your dependencies:

* `LIBDSE_ROOT_DIR`
* `LIBUV_ROOT_DIR`

## Dependencies

* [cmake]  (>= 2.6.4)
* C/C++ DataStax Enterprise Driver (it can be downloaded from our [downloads
  site])
* [libuv] (also required by the driver and can also be download from our
  [downloads site])

[documentation site]: https://docs.datastax.com/en/developer/cpp-driver-dse/latest
[downloads site]: https://downloads.datastax.com/cpp-driver
[libuv]: https://github.com/libuv/libuv
[cmake]: https://cmake.org
