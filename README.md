# Integration tests

## Setup

- Choose to run the application (1)locally with Ruby or (2)inside docker

## Local Setup

- Install ruby 2.7
- Chrome installation is required
- `bundle install`

### Local Test Execution

- `rspec spec`

## Docker Setup

```
docker-compose up -d --build
```

### Docker Test Execution

#### Development
_The development environment must be started explicitly._

Run tests ingesting a single file (this is the default test).
```
docker-compose run --rm -e INTEG_TEST_ENV=development mrt-integ-tests
```

Run tests without ingesting files
```
docker-compose run --rm -e INTEG_TEST_ENV=development -e INGEST_FILES=none mrt-integ-tests
```

Run tests without ingesting files **on a preview URL**
```
docker-compose run --rm -e INTEG_TEST_ENV=development -e INGEST_FILES=none -e PREVIEW_URL='https://...' mrt-integ-tests
```

Run tests with full encoding tests

_This test takes a long time to complete -- only run this option if you have a need to test file name encoding issues._
```
docker-compose run --rm -e INTEG_TEST_ENV=development -e INGEST_FILES=encoding-tests mrt-integ-tests
```
#### Stage
_This must be run from an environment with SSM enabled._

Run tests ingesting a single file (this is the default test).
```
docker-compose run --rm -e INTEG_TEST_ENV=stage mrt-integ-tests
```

Run tests without ingesting files
```
docker-compose run --rm -e INTEG_TEST_ENV=stage -e INGEST_FILES=none mrt-integ-tests
```

Run tests without ingesting files **on a preview URL**
```
docker-compose run --rm -e INTEG_TEST_ENV=stage -e INGEST_FILES=none -e PREVIEW_URL='https://...' mrt-integ-tests
```

Run tests with full encoding tests

_This test takes a long time to complete -- only run this option if you have a need to test file name encoding issues._
```
docker-compose run --rm -e INTEG_TEST_ENV=stage -e INGEST_FILES=encoding-tests mrt-integ-tests
```

#### Production
_This must be run from an environment with SSM enabled._

Run tests ingesting a single file (this is the default test).
```
docker-compose run --rm -e INTEG_TEST_ENV=production mrt-integ-tests
```

Run tests without ingesting files
```
docker-compose run --rm -e INTEG_TEST_ENV=production -e INGEST_FILES=none mrt-integ-tests
```

Run tests without ingesting files **on a preview URL**
```
docker-compose run --rm -e INTEG_TEST_ENV=production -e INGEST_FILES=none -e PREVIEW_URL='https://...' mrt-integ-tests
```

Run tests with full encoding tests

_This test takes a long time to complete -- only run this option if you have a need to test file encoding issues._
```
docker-compose run --rm -e INTEG_TEST_ENV=production -e INGEST_FILES=encoding-tests mrt-integ-tests
```

### Cleanup
```
docker-compose down
```
