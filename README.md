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
The development environment must be started explicitly.
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
```
docker-compose run --rm -e INTEG_TEST_ENV=development -e INGEST_FILES=encoding-tests mrt-integ-tests
```
#### Stage
This must be run from an environment with SSM enabled
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
```
docker-compose run --rm -e INTEG_TEST_ENV=stage -e INGEST_FILES=encoding-tests mrt-integ-tests
```

#### Production
This must be run from an environment with SSM enabled
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
```
docker-compose run --rm -e INTEG_TEST_ENV=production -e INGEST_FILES=encoding-tests mrt-integ-tests
```

### Cleanup
```
docker-compose down
```
