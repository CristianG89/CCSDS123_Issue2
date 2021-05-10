# ***********************************************************************************
# ************************* VUNIT AND LIBRARY INITIALIZATION ************************
# ***********************************************************************************

# Load required libraries from VUnit
from os.path import join, dirname
# The public interface of VUnit
from vunit import VUnit
# Computes the cartesian product of input iterables
from itertools import product
# Load required functions for testcase files load
from os import listdir

# Returns the directory name where the present file (run.py) is located
root = dirname(__file__)

# Create VUnit instance by parsing command line arguments
ui = VUnit.from_argv()

# Add random numbers generation package
ui.add_random()
# Add verification component library
ui.add_verification_components()
# Add communication package
ui.add_com()

# Create library 'vunit_lib'
vunit_lib = ui.library("vunit_lib")

# Add all package files
vunit_lib.add_source_files(join(root, "../../../Image/_packages/*.vhd"))
vunit_lib.add_source_files(join(root, "../../_packages/*.vhd"))

# Add all sources files from Predictor IP
vunit_lib.add_source_files(join(root, "../../../Image/img_coord_ctrl.vhd"))
vunit_lib.add_source_files(join(root, "../*.vhd"))

# Add testbench file from Predictor IP
vunit_lib.add_source_files(join(root, "tb_top_quantizer.vhd"))

# To encode the parameters, the script must contain the encode function
def encode(tb_cfg):
    return ",".join(["%s:%s" % (key, str(tb_cfg[key])) for key in tb_cfg])

# ***********************************************************************************
# ***************************** TESTBENCHES PARAMETERS ******************************
# ***********************************************************************************

# A list of parameters are defined, then saved and finally encoded to be in the testbench
def gen_predictor_tests(obj, fidel_type, abs_err_type, rel_err_type):
    for fidel_type, abs_err_type, rel_err_type in product(fidel_type, abs_err_type, rel_err_type):
        tb_cfg = dict(
            FIDEL_TYPE_PY=fidel_type,
            ABS_ERR_TYPE_PY=abs_err_type,
            REL_ERR_TYPE_PY=rel_err_type
        )
        config_name = encode(tb_cfg)
        obj.add_config(name=config_name, generics=dict(encoded_tb_cfg=encode(tb_cfg)))

# ***********************************************************************************
# ****************************** GENERATE TESTBENCHES *******************************
# ***********************************************************************************

# Everytime a new testbench is here requested (it can be the same with different parameters),
# all test cases in the VHDL testbench file will be executed again.
tb_top_quantizer = vunit_lib.test_bench("tb_top_quantizer")
for test in tb_top_quantizer.get_tests():
    # if test.name == "LiteBus - Modifying SPI config":
        gen_predictor_tests(test, [0, 1, 2, 3], ['0', '1'], ['0', '1'])

# ***********************************************************************************
# ********************************** MAIN FUNCTION **********************************
# ***********************************************************************************

ui.main()