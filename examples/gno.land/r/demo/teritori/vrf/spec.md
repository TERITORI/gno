# VRF

For VRF 0.1 for Gnoland, we will use following mechanism.

- VRF data feeders are available and only those can feed data
- Long data bytes will be feed into the realm by multiple feeders
- All of the values provided from those feeders will be combined to generate random data (This will make the random secure enough e.g. when 1 feeder is attacked for server attack - just need at least one trustworthy data feeder)
- Random data is written up-on the request. That way, noone knows what will be written at the time of requesting randomness.

## Use case

VRF can be used by offchain users to request random data or by other realms to get TRUE random value on their operations.

The initial use case is on Justice DAO to determine random members to get voting power on the DAO to resolve conflict between service providers and customers when there are issues between them.

## Data structure

VRF utilize two structs, `Config` for feeders administration, and `Request` to manage the state of random requests by id.

```go
type Config struct {
	vrfAdmin string
	feeders  []string
}
```

```go
type Request struct {
	id                   uint64
	requesterAddress     string
	requesterRealm       string
	requiredFeedersCount uint64
	fulfilledCount       uint64
	randomWords          []byte
	fulfillers           []string
}
```

## Realm configuration process

After realm deployment, VRF admin is set by using `SetVRFAdmin` endpoint.

By VRF admin, feeders are set by using `SetFeeders` endpoint.

Feeders can be modified by VRF admin at any time.

Note: The random data that's already feed by feeder can not be cancelled by VRF admin.

## Random data generation process

- A user or realm request random words from feedeers by using `RequestRandomWords` endpoint
- Feeders monioring the requests check not filled requests and add random words by running `FulfillRandomWords` endpoint
- The requester can use `RandomValueFromWordsWithIndex` or `RandomValueFromWords` based on the required number of random values

## Improvement thoughts

### Continuously consuming VRF request

On VRF 0.1, one request is designed for one time use. There might be a possibility where a realm continuously requires random numbers based on interval. And requesting it everytime would require bad UX.

### Transfering the ownership of VRF to DAO

To get better trust on VRF, the owner of the VRF will need to be a DAO realm.

### Random data source

There should be a software that the feeders run and the versions should be managed, the version should be compatible with the VRF realm.
The software should fetch the bytes from verifiable source to avoid manipulation.

### VRF random data feeders performance counting

It can count the number of requests fulfilled for up-time calculation.
And it would be good to add sort of verifiers to ensure that the random data sent is accurate.

### VRF random data feeders incentives

It would be good to add sort of mechanism for rewards distribution to random data feeders.

### VRF random data feeders onboarding flow

VRF 0.1 is assuming the owner set the data feeders directly, it would be good to let feeders to send request through realm with social profiles, and get it approved by DAO to join as random data feeder.

### Random data feeders profile management

Random data feeders can maintain their profile.
