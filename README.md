# CCSDS123_Issue2
VHDL implementation of the CCSDS123 (Issue 2) compression algorithm.

## Top entity
It is composed of two parts:
1. The Predictor block: Predicts the new samples, based on the nearby ones.
2. The Encoder block: Encodes the image).

There is an indepedent IP per single operation, so the complete design offers a high level of modularity and re-usability.

## Predictor

This block is a closed loop that allows for either lossless or near-lossless compression. It has 4 major sub-blocks plus an adder:
- Adder IP
- Quantizer IP
- Mapper IP
- Sample Representative IP
- Prediction IP

### NOTE
Refer to file "Block Diagram" to see a block diagram of each sub-block from above as well as Predictor top module. 

## Encoder

To be continued for the Master Thesis.
