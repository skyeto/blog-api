# Blog Api

Contains most of the API code for my blog. It currently includes the server side implementation of proof-of-work challenges but does not include my server-side PrivacyPass implementation for signing blinded tokens and verifying redemption's. (Implemented as a microservice in Rust)

Includes:
* RTMP streaming endpoint
* HLS manifest generation and storage to S3 compatible endpoint
* Segment/media encryption
* Blake2b proof-of-work

This was quickly thrown together, so there's plenty of refactoring left to do, especially on the audio pipeline (support multiple streaming sources etc.).

Licensed under AGPL-3.0 unless otherwise specified.

