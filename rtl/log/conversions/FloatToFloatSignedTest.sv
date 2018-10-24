// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module FloatToFloatSignedTest();
  localparam EXP = 5;
  localparam FRAC = 11;

  // Expand to a type that can capture the denormals
  localparam SIGNED_EXP = 6;
  localparam SIGNED_FRAC = 11;

  Float #(.EXP(EXP), .FRAC(FRAC)) floatIn();
  FloatSigned #(.EXP(SIGNED_EXP), .FRAC(SIGNED_FRAC)) signedFloatOut();

  FloatToFloatSigned #(.EXP(EXP),
                       .FRAC(FRAC),
                       .SIGNED_EXP(SIGNED_EXP),
                       .SIGNED_FRAC(SIGNED_FRAC))
  f2fs(.in(floatIn),
       .out(signedFloatOut));

  Float #(.EXP(8), .FRAC(23)) floatOut();

  FloatSignedToFloat #(.SIGNED_EXP(SIGNED_EXP),
                       .SIGNED_FRAC(SIGNED_FRAC),
                       .EXP(8),
                       .FRAC(23))
  fs2f(.in(signedFloatOut),
       .out(floatOut));

  logic isInf;
  logic isNan;
  logic isZero;
  logic isDenormal;

  FloatProperties #(.EXP(EXP),
                    .FRAC(FRAC))
  fprop(.in(floatIn),
        .isInf,
        .isNan,
        .isZero,
        .isDenormal);

  integer i;

  initial begin
    // Test denormal expansion
    for (i = 0; i < 10; ++i) begin
      floatIn.data.sign = $random;
      floatIn.data.exponent = EXP'(1'b0);
      floatIn.data.fraction = $random;
      #1;

      assert(isDenormal);
      assert(floatIn.toReal(floatIn.data) == $bitstoshortreal(floatOut.data));
    end

    // Test other values
    for (i = 0; i < 1000; ++i) begin
      floatIn.data = $random;
      #1;

      if (isInf || isNan) begin
        assert(floatOut.isInf(floatOut.data));
      end else if (isZero) begin
        assert(floatOut.isZero(floatOut.data));
      end else begin
        if (floatIn.toReal(floatIn.data) != $bitstoshortreal(floatOut.data)) begin
          $display("%s %g -> %s %g",
                   floatIn.print(floatIn.data),
                   floatIn.toReal(floatIn.data),
                   floatOut.print(floatOut.data),
                   floatOut.toReal(floatOut.data));
        end

        assert(floatIn.toReal(floatIn.data) == $bitstoshortreal(floatOut.data));
      end
    end
  end
endmodule
