#!/usr/bin/env python3
"""Regression for blackbox declarations such as HardFloat's multiline modules."""
import pathlib
import runpy
import sys
import tempfile
import unittest
from unittest.mock import patch


class ModuleDeclarationsTest(unittest.TestCase):
    def test_multiline_parameterized_blackboxes(self):
        script = pathlib.Path(__file__).with_name("uniquify-module-names.py")
        required = ("model-hier-json", "top-hier-json", "in-all-filelist",
                    "in-bb-filelist", "dut", "model", "out-dut-filelist",
                    "out-model-filelist", "out-model-hier-json", "target-dir", "gcpath")
        argv = [str(script)] + [arg for key in required for arg in ("--" + key, "unused")]
        with patch.object(sys, "argv", argv):
            parse = runpy.run_path(str(script))["get_modules_in_verilog_file"]
        with tempfile.TemporaryDirectory() as directory:
            source = pathlib.Path(directory) / "blackbox.sv"
            source.write_text("""
// module not_a_module(input a);
/*
module also_not_a_module;
*/
module main(input clock); endmodule
module
    reverse#(parameter width = 1)(input [width-1:0] in);
endmodule
module /* comment between keyword and name */
    countLeadingZeros #(parameter width = 8)();
endmodule
module automatic helper(); endmodule
""")
            self.assertEqual(parse(source), ["main", "reverse", "countLeadingZeros", "helper"])


if __name__ == "__main__":
    unittest.main()
