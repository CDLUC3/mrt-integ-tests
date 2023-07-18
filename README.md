# Merritt Integration Test Driver

This library is part of the [Merritt Preservation System](https://github.com/CDLUC3/mrt-doc).

[![](https://github.com/CDLUC3/mrt-doc/raw/main/diagrams/integ-tests.mmd.svg)](https://cdluc3.github.io/mrt-doc/diagrams/integ-tests)

## Setup

- Choose to run the application (1)locally with Ruby or (2)inside docker

## Local Setup

- Install ruby 3.0
- Chrome installation is required
- `bundle install`

### Local Test Execution

- `rspec spec`

## Docker Setup

```
docker-compose build
docker-compose up -d chrome
```

### Docker Test Execution

| Domain | Scenario | Command |
| ------ | -------- | ------- |
| Production | Patching: Simple Ingest (queue __unpaused__)| `docker-compose run --rm -e INTEG_TEST_ENV=production mrt-integ-tests`|
| Production | Patching: Retrieval only (queue __paused__)| `docker-compose run --rm -e INTEG_TEST_ENV=production -e PREFIX=2022_03_14_1712 mrt-integ-tests`|
| Production | No Ingest | `docker-compose run --rm -e INTEG_TEST_ENV=production -e INGEST_FILES=none mrt-integ-tests`|
| Production | Ingest Full Encoding Tests | `docker-compose run --rm -e INTEG_TEST_ENV=production -e INGEST_FILES=encoding-tests mrt-integ-tests`|
| Production | Preview Url | `docker-compose run --rm -e INTEG_TEST_ENV=production -e PREFIX=2022_03_14_1712 -e PREVIEW_URL='https://...' mrt-integ-tests`|
| Stage | Patching: Simple Ingest (queue __unpaused__)| `docker-compose run --rm -e INTEG_TEST_ENV=stage mrt-integ-tests`|
| Stage | Patching: Retrieval only (queue __paused__) | `docker-compose run --rm -e INTEG_TEST_ENV=stage -e PREFIX=2022_03_16_1520 mrt-integ-tests`|
| Stage | No Ingest | `docker-compose run --rm -e INTEG_TEST_ENV=stage -e INGEST_FILES=none mrt-integ-tests`|
| Stage | Ingest Full Encoding Tests | `docker-compose run --rm -e INTEG_TEST_ENV=stage -e INGEST_FILES=encoding-tests mrt-integ-tests`|
| Stage | Preview Url | `docker-compose run --rm -e INTEG_TEST_ENV=stage -e PREFIX=2022_03_16_1520 -e PREVIEW_URL='https://...' mrt-integ-tests`|
| Development | Simple Ingest | `docker-compose run --rm -e INTEG_TEST_ENV=development mrt-integ-tests`|
| Development | No Ingest | `docker-compose run --rm -e INTEG_TEST_ENV=development -e INGEST_FILES=none mrt-integ-tests`|
| Development | Preview Url | `docker-compose run --rm -e INTEG_TEST_ENV=development -e INGEST_FILES=none -e PREVIEW_URL='https://...' mrt-integ-tests`|

### Cleanup
```
docker-compose down
```

## Running outside of docker
- Comment out `CHROME_URL: http://chrome:4444/wd/hub`
- `bundle install`
- `INTEG_TEST_ENV=... bundle exec rspec`
