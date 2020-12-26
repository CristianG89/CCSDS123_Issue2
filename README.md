# CCSDS123_Issue2
VHDL implementation of the CCSDS123 (Issue 2) compression algorithm.

## Top entity
It is composed of two parts:
1. The Predictor block: Predicts the new samples, based on the nearby ones.
2. The Encoder block: Encodes the image).

## Predictor

This block is a closed loop that allows for either lossless or near-lossless compression. It has 4 major sub-blocks plus an adder:
- Adder IP
- Quantizer IP
- Mapper IP
- Sample Representative IP
- Prediction IP

## Encoder

To be continued for the Master Thesis.
