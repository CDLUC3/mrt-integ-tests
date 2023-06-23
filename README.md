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

## Sample Successful run

_Abstract specific URL's for github..._

```
bash-4.2$ docker-compose run --rm -e INTEG_TEST_ENV=stage mrt-integ-tests
Creating mrt-integ-tests_mrt-integ-tests_run ... done
stage: 2022_05_11_1020

basic_merrit_ui_tests
  Verify that the Merritt UI home page is accessible
  Verify that a semantic version string is accessible in the Merritt UI footer
        Version: 1.1.12-dev7
    Print footer
  Enumerate test files
        Ingest Files:
  Version Files:
                v1file          v1_file.md
  Encoding zip:
                md              README.md
                space           README 1.md
                plus            README+2.md
                percent         README %AF.md
                percent2        Test50%majrule.txt
                percent3        Z_5%_400C-bet.xlsx
                accent          README cliché.md
                pipe            README|pipe.md
    Print the test files to be used for ingest and retrieval tests -- based on -e INGEST_FILES
  Check storage service state
        http://url.not.shown/state/9502
          Node State OK: true
        http://url.not.shown/state/4101
          Node State OK: true
        http://url.not.shown/state/3042
          Node State OK: true
        http://url.not.shown/state/2002
          Node State OK: true
        http://url.not.shown/state/5001
          Node State OK: true
        http://url.not.shown/state/6001
          Node State OK: true
    Invoke the storage state command for each storage node -- this tests the accessibility of each cloud service used by Merritt
  Check service states
    Verify that the microservice STATE endpoint returns a successful response: http://url.not.shown/state.json
    Using the STATE endpoint response, verify that processing is not frozen for the micorservice: http://url.not.shown/state.json
                1.1.12-dev7
    Extract microservice build info (build.content.txt for java microservices): http://url.not.shown/state.json
    Verify that the microservice STATE endpoint returns a successful response: http://url.not.shown/state.json
    Using the STATE endpoint response, verify that processing is not frozen for the micorservice: http://url.not.shown/state.json
                1.1.12-dev7
    Extract microservice build info (build.content.txt for java microservices): http://url.not.shown/state.json
    Verify that the microservice STATE endpoint returns a successful response: http://url.not.shown/state?t=json
    Using the STATE endpoint response, verify that processing is not frozen for the micorservice: http://url.not.shown/state?t=json
                Building tag 0.0.25
    Extract microservice build info (build.content.txt for java microservices): http://url.not.shown/static/build.content.txt
    Verify that the microservice STATE endpoint returns a successful response: http://url.not.shown/state?t=json
    Using the STATE endpoint response, verify that processing is not frozen for the micorservice: http://url.not.shown/state?t=json
                Building tag 0.0.25
    Extract microservice build info (build.content.txt for java microservices): http://url.not.shown/static/build.content.txt
    Verify that the microservice STATE endpoint returns a successful response: http://url.not.shown/state?t=json
    Using the STATE endpoint response, verify that processing is not frozen for the micorservice: http://url.not.shown/state?t=json
    Extract microservice build info (build.content.txt for java microservices): http://url.not.shown/static/build.content.txt (PENDING: Microservice build info endpoint is not yet enabled)
    Verify that the microservice STATE endpoint returns a successful response: http://url.not.shown/state?t=json
    Using the STATE endpoint response, verify that processing is not frozen for the micorservice: http://url.not.shown/state?t=json
    Extract microservice build info (build.content.txt for java microservices): http://url.not.shown/static/build.content.txt (PENDING: Microservice build info endpoint is not yet enabled)
    Verify that the microservice STATE endpoint returns a successful response: http://url.not.shown/mrtaudit/state?t=json
    Using the STATE endpoint response, verify that processing is not frozen for the micorservice: http://url.not.shown/mrtaudit/state?t=json
                Building tag 0.0.19
    Extract microservice build info (build.content.txt for java microservices): http://url.not.shown/mrtaudit/static/build.content.txt
    Verify that the microservice STATE endpoint returns a successful response: http://url.not.shown/mrtaudit/state?t=json
    Using the STATE endpoint response, verify that processing is not frozen for the micorservice: http://url.not.shown/mrtaudit/state?t=json
                Building tag 0.0.19
    Extract microservice build info (build.content.txt for java microservices): http://url.not.shown/mrtaudit/static/build.content.txt
    Verify that the microservice STATE endpoint returns a successful response: http://url.not.shown/mrtinv/state?t=json
    Using the STATE endpoint response, verify that processing is not frozen for the micorservice: http://url.not.shown/mrtinv/state?t=json
                Building tag 0.0.9
    Extract microservice build info (build.content.txt for java microservices): http://url.not.shown/mrtinv/static/build.content.txt
    Verify that the microservice STATE endpoint returns a successful response: http://url.not.shown/mrtinv/state?t=json
    Using the STATE endpoint response, verify that processing is not frozen for the micorservice: http://url.not.shown/mrtinv/state?t=json
                Building tag 0.0.9
    Extract microservice build info (build.content.txt for java microservices): http://url.not.shown/mrtinv/static/build.content.txt
    Verify that the microservice STATE endpoint returns a successful response: http://url.not.shown/mrtoai/state?t=json
    Using the STATE endpoint response, verify that processing is not frozen for the micorservice: http://url.not.shown/mrtoai/state?t=json
    Extract microservice build info (build.content.txt for java microservices): http://url.not.shown/mrtoai/static/build.content.txt (PENDING: Microservice build info endpoint is not yet enabled)
    Verify that the microservice STATE endpoint returns a successful response: http://url.not.shown/mrtreplic/state?t=json
    Using the STATE endpoint response, verify that processing is not frozen for the micorservice: http://url.not.shown/mrtreplic/state?t=json
                Building tag 0.0.4
    Extract microservice build info (build.content.txt for java microservices): http://url.not.shown/mrtreplic/static/build.content.txt
    Verify that the microservice STATE endpoint returns a successful response: http://url.not.shown/mrtreplic/state?t=json
    Using the STATE endpoint response, verify that processing is not frozen for the micorservice: http://url.not.shown/mrtreplic/state?t=json
                Building tag 0.0.4
    Extract microservice build info (build.content.txt for java microservices): http://url.not.shown/mrtreplic/static/build.content.txt
    Verify that the microservice STATE endpoint returns a successful response: http://url.not.shown/state?t=json
    Using the STATE endpoint response, verify that processing is not frozen for the micorservice: http://url.not.shown/state?t=json
    Extract microservice build info (build.content.txt for java microservices): http://url.not.shown/static/build.content.txt (PENDING: Microservice build info endpoint is not yet enabled)
    Verify that the microservice STATE endpoint returns a successful response: http://url.not.shown/state?t=json
    Using the STATE endpoint response, verify that processing is not frozen for the micorservice: http://url.not.shown/state?t=json
    Extract microservice build info (build.content.txt for java microservices): http://url.not.shown/static/build.content.txt (PENDING: Microservice build info endpoint is not yet enabled)
    View state page - look for audit replic errors
      From the UI state endpoint page, verify that no recent AUDIT errors have occurred (PENDING: Audit counts are not verified within this environment -- stage has known checksum errors)
      From the UI state endpoint page, verify that no recent REPLICATION errors have occurred
      From the UI state endpoint page, verify that AUDIT activity is occurring
  Check service states via load balancers
    Verify that the STATE endpoint is accessible and successful when invoked from a load balancer: http://url.not.shown/state.json
    Verify that the STATE endpoint is accessible and successful when invoked from a load balancer: http://url.not.shown/state?t=json
    Verify that the STATE endpoint is accessible and successful when invoked from a load balancer: http://url.not.shown/mrtinv/state?t=json
    Verify that the STATE endpoint is accessible and successful when invoked from a load balancer: http://url.not.shown/state?t=json
    Verify that the STATE endpoint is accessible and successful when invoked from a load balancer: http://url.not.shown/ingest/state?t=json
  Unauthenticated Access
    Verify that the Guest Login button succeeds in the Merritt UI
    Verify that COLLECTIONS accessible to the Guest Login can be browsed
    Verify that OBJECTS accessible to the Guest Login can be browsed
    Verify that the JSON OBJECT_INFO page for an object accessible to the Guest Login can be retrieved
    Verify that the JSON OBJECT_INFO page for an object accessible to the Guest Login CANNOT be retrieved IF the user is not logged in
    Verify that a VERSION PAGE for an object accessible to the Guest Login can be browsed
    Verify that a FILE for an object accessible to the Guest Login REDIRECTS to a presigned file retrieval
    Verify that the ATOM FEED for a collection accessible to the Guest Login can be browsed
    Verify the CONTENT of a FILE for an object accessible to the Guest Login
    Verify that the GUEST login user cannot browse collections that are not authorized to the Guest login
  Authenticated access
    Verify the CONTENT of a FILE for an object in a collection NOT acessible to the GUEST login
    ingest files
      Verify that a ZIP FILE named 'encoding.zip' containing multiple files can be ingested into an object
      Create VERSION 1 of an object using the following PREFIX as part of its local_id:  v1file
        Sleep 30 (to allow upload to complete)
        Verify that VERSION 1 can be ingested for the following file: v1_file.md
      Create VERSION 2 of an object using the following PREFIX as part of its local_id: v1file
        Sleep 10 (to allow upload to complete)
        Verify that VERSION 2 can be ingested for the following file: v1_file.md
        Sleep 80 (to allow ingests to complete)
    Browse the OBJECT and FILES ingested as a part of ENCODING.ZIP
      Verify that a FILENAME with the following CHARACTERS can be retrieved from the object: README.md
      Verify that a SINGLY ENCODED or DOUBLY ENCODED FILENAME with the following CHARACTERS can be retrieved from the object: README.md
      Verify that a FILENAME with the following CHARACTERS can be retrieved from the object: README 1.md
      Verify that a SINGLY ENCODED or DOUBLY ENCODED FILENAME with the following CHARACTERS can be retrieved from the object: README 1.md
      Verify that a FILENAME with the following CHARACTERS can be retrieved from the object: README+2.md
      Verify that a SINGLY ENCODED or DOUBLY ENCODED FILENAME with the following CHARACTERS can be retrieved from the object: README+2.md
      Verify that a FILENAME with the following CHARACTERS can be retrieved from the object: README %AF.md
      Verify that a SINGLY ENCODED or DOUBLY ENCODED FILENAME with the following CHARACTERS can be retrieved from the object: README %AF.md
      Verify that a FILENAME with the following CHARACTERS can be retrieved from the object: Test50%majrule.txt
      Verify that a SINGLY ENCODED or DOUBLY ENCODED FILENAME with the following CHARACTERS can be retrieved from the object: Test50%majrule.txt
      Verify that a FILENAME with the following CHARACTERS can be retrieved from the object: Z_5%_400C-bet.xlsx
      Verify that a SINGLY ENCODED or DOUBLY ENCODED FILENAME with the following CHARACTERS can be retrieved from the object: Z_5%_400C-bet.xlsx
      Verify that a FILENAME with the following CHARACTERS can be retrieved from the object: README cliché.md
      Verify that a SINGLY ENCODED or DOUBLY ENCODED FILENAME with the following CHARACTERS can be retrieved from the object: README cliché.md
      Verify that a FILENAME with the following CHARACTERS can be retrieved from the object: README|pipe.md
      Verify that a SINGLY ENCODED or DOUBLY ENCODED FILENAME with the following CHARACTERS can be retrieved from the object: README|pipe.md
        Sleep 30 (to allow assembly of ark_99999_fk4ks86n31.zip to complete)
        Sleep 5 (to allow download link to appear)
        Sleep 30 (to allow download of ark_99999_fk4ks86n31.zip to complete)
List contents of /tmp/downloads
Z_5%_400C-bet (1).xlsx
Z_5%_400C-bet.xlsx
ark_99999_fk4ks86n31.zip
Zip file listing
ark+=99999=fk4ks86n31/1/producer/README|pipe.md
ark+=99999=fk4ks86n31/1/producer/README %AF.md
ark+=99999=fk4ks86n31/1/producer/README+2.md
ark+=99999=fk4ks86n31/1/producer/README.md
ark+=99999=fk4ks86n31/1/producer/README cliché.md
ark+=99999=fk4ks86n31/1/producer/Z_5%_400C-bet.xlsx
ark+=99999=fk4ks86n31/1/producer/README 1.md
ark+=99999=fk4ks86n31/1/producer/Test50%majrule.txt
      Verify that the OBJECT CAN BE DOWNLOADED and that it contains ALL the files within ENCODING.ZIP:
    Browse Objects recently INGESTED and UPDATED (VERSIONED)
      search for object with 2022_05_11_1020_v1file
        Verify browse of a RECENTLY INGESTED OBJECT with local id: 2022_05_11_1020_v1file
        Verify the presence of a TEST FILE on the OBJECT PAGE: v1_file.md
        Verify the presence of a TEST FILE on the VERSION 1 PAGE: v1_file.md
        Verify the RETRIEVAL OF VERSION 1 of A TEST FILE v1_file.md by URL construction
        Verify the presence of a TEST FILE on the VERSION 2 PAGE: v1_file.md.v2
        Verify the RETRIEVAL OF VERSION 2 of A TEST FILE v1_file.md.v2 by URL construction
        Verify AUDIT AND REPLIC stats for a recently ingested and updated object v1file


Finished in 8 minutes 31 seconds (files took 4.2 seconds to load)
95 examples, 0 failures, 6 pending
```

Note that 6 tests were PENDING (as of the date this README was updated).  The last pending item is specific to the stage environment.
```
    Extract microservice build info (build.content.txt for java microservices): http://url.not.shown/static/build.content.txt (PENDING: Microservice build info endpoint is not yet enabled)
    Extract microservice build info (build.content.txt for java microservices): http://url.not.shown/static/build.content.txt (PENDING: Microservice build info endpoint is not yet enabled)
    Extract microservice build info (build.content.txt for java microservices): http://url.not.shown/mrtoai/static/build.content.txt (PENDING: Microservice build info endpoint is not yet enabled)
    Extract microservice build info (build.content.txt for java microservices): http://url.not.shown/static/build.content.txt (PENDING: Microservice build info endpoint is not yet enabled)
    Extract microservice build info (build.content.txt for java microservices): http://url.not.shown/static/build.content.txt (PENDING: Microservice build info endpoint is not yet enabled)
      From the UI state endpoint page, verify that no recent AUDIT errors have occurred (PENDING: Audit counts are not verified within this environment -- stage has known checksum errors)
```

## TEST Referencing PREVIOUS INGEST `-e PREFIX=2022_05_11_1020`

_3 additional PENDING Tests_

```
      Verify that a ZIP FILE named 'encoding.zip' containing multiple files can be ingested into an object (PENDING: PREFIX supplied - this substitutes for the ingest)
        Verify that VERSION 1 can be ingested for the following file: v1_file.md (PENDING: PREFIX supplied - this substitutes for the ingest)
        Verify that VERSION 2 can be ingested for the following file: v1_file.md (PENDING: PREFIX supplied - this substitutes for the ingest)

Finished in 6 minutes 0 seconds (files took 4.38 seconds to load)
95 examples, 0 failures, 9 pending
```

## TEST with NO INGEST `-e INGEST_FILES=none`

```
Finished in 1 minute 35.29 seconds (files took 4.31 seconds to load)
68 examples, 0 failures, 6 pending
```

## TEST with NO INGEST -- INGEST Queue Frozen

```
    Using the STATE endpoint response, verify that processing is not frozen for the micorservice: http://url.not.shown/state?t=json (FAILED - 1)
    Using the STATE endpoint response, verify that processing is not frozen for the micorservice: http://url.not.shown/state?t=json (FAILED - 2)

Finished in 1 minute 38.31 seconds (files took 4.27 seconds to load)
68 examples, 2 failures, 6 pending
```

## Test with INGEST -- INGEST Queue Frozen

_24 additional failures will be generated because the ingests will not complete before the browse is attempted._

```
      Verify that a FILENAME with the following CHARACTERS can be retrieved from the object: README.md (FAILED - 3)
      Verify that a SINGLY ENCODED or DOUBLY ENCODED FILENAME with the following CHARACTERS can be retrieved from the object: README.md (FAILED - 4)
      Verify that a FILENAME with the following CHARACTERS can be retrieved from the object: README 1.md (FAILED - 5)
      Verify that a SINGLY ENCODED or DOUBLY ENCODED FILENAME with the following CHARACTERS can be retrieved from the object: README 1.md (FAILED - 6)
      Verify that a FILENAME with the following CHARACTERS can be retrieved from the object: README+2.md (FAILED - 7)
      Verify that a SINGLY ENCODED or DOUBLY ENCODED FILENAME with the following CHARACTERS can be retrieved from the object: README+2.md (FAILED - 8)
      Verify that a FILENAME with the following CHARACTERS can be retrieved from the object: README %AF.md (FAILED - 9)
      Verify that a SINGLY ENCODED or DOUBLY ENCODED FILENAME with the following CHARACTERS can be retrieved from the object: README %AF.md (FAILED - 10)
      Verify that a FILENAME with the following CHARACTERS can be retrieved from the object: Test50%majrule.txt (FAILED - 11)
      Verify that a SINGLY ENCODED or DOUBLY ENCODED FILENAME with the following CHARACTERS can be retrieved from the object: Test50%majrule.txt (FAILED - 12)
      Verify that a FILENAME with the following CHARACTERS can be retrieved from the object: Z_5%_400C-bet.xlsx (FAILED - 13)
      Verify that a SINGLY ENCODED or DOUBLY ENCODED FILENAME with the following CHARACTERS can be retrieved from the object: Z_5%_400C-bet.xlsx (FAILED - 14)
      Verify that a FILENAME with the following CHARACTERS can be retrieved from the object: README cliché.md (FAILED - 15)
      Verify that a SINGLY ENCODED or DOUBLY ENCODED FILENAME with the following CHARACTERS can be retrieved from the object: README cliché.md (FAILED - 16)
      Verify that a FILENAME with the following CHARACTERS can be retrieved from the object: README|pipe.md (FAILED - 17)
      Verify that a SINGLY ENCODED or DOUBLY ENCODED FILENAME with the following CHARACTERS can be retrieved from the object: README|pipe.md (FAILED - 18)
      Verify that the OBJECT CAN BE DOWNLOADED and that it contains ALL the files within ENCODING.ZIP: (FAILED - 19)
    Browse Objects recently INGESTED and UPDATED (VERSIONED)
      search for object with 2022_05_11_1055_v1file
        Verify browse of a RECENTLY INGESTED OBJECT with local id: 2022_05_11_1055_v1file (FAILED - 20)
        Verify the presence of a TEST FILE on the OBJECT PAGE: v1_file.md (FAILED - 21)
        Verify the presence of a TEST FILE on the VERSION 1 PAGE: v1_file.md (FAILED - 22)
        Verify the RETRIEVAL OF VERSION 1 of A TEST FILE v1_file.md by URL construction (FAILED - 23)
        Verify the presence of a TEST FILE on the VERSION 2 PAGE: v1_file.md.v2 (FAILED - 24)
        Verify the RETRIEVAL OF VERSION 2 of A TEST FILE v1_file.md.v2 by URL construction (FAILED - 25)
        Verify AUDIT AND REPLIC stats for a recently ingested and updated object v1file (FAILED - 26)

Finished in 7 minutes 8 seconds (files took 4.53 seconds to load)
95 examples, 26 failures, 6 pending
```

## TEST with NO INGEST -- REPLIC Queue Frozen on one instance

```
    Using the STATE endpoint response, verify that processing is not frozen for the micorservice: http://url.not.shown/mrtreplic/state?t=json (FAILED - 1)

Finished in 1 minute 36.55 seconds (files took 4.44 seconds to load)
68 examples, 1 failure, 6 pending
```
