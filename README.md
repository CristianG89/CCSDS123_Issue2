# CCSDS123_Issue2
VHDL implementation of the CCSDS123 (Issue 2) compression algorithm.

It is composed of two parts:
The Predictor block (which predicts the new samples, based on the nearby ones), and the Encoder block (which encodes the image).

########################## PREDICTOR ##########################

This block is a closed loop that allows for either lossless or near-lossless compression. It has 4 major sub-blocks plus an adder:
- Adder IP
- Quantizer IP
- Mapper IP
- Sample Representative IP
- Prediction IP

########################### ENCODER ###########################

To be continued for the Master Thesis.