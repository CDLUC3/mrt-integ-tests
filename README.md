# Integration tests

## Setup

- Copy `config/test_config.yml.template` to `config/test_config.yml`
- Customize the credentials and default environment
- Choose to run the application (1)locally with Ruby or (2)inside docker

## Local Setup

- Install ruby 2.7
- Chrome installation is required
- `bundle install`

### Local Test Execution

- `rspec spec`

## Docker Setup

```
docker-compose build
docker-compose up -d
```

### Docker Test Execution

```
docker-compose run --rm mrt-integ-tests
```

### Cleanup
```
docker-compose down
```
