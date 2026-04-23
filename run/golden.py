import numpy as np
import argparse

def main(R, K, C, DIR):
    rng = np.random.default_rng(1234)

    k = rng.integers(-128, 127, size=(K, R), dtype=np.int32)
    x = rng.integers(-128, 127, size=(K, R), dtype=np.int32)
    a = rng.integers(-32768, 32767, size=(K, R), dtype=np.int32)

    with open(f"{DIR}/kxa.bin", "wb") as f:
        f.write(k.astype(np.int8).tobytes())
        f.write(x.astype(np.int8).tobytes())
        f.write(a.astype(np.int32).tobytes())

    y = (k.astype(np.int64) * x.astype(np.int64) + a.astype(np.int64)).astype(np.int32)

    with open(f"{DIR}/y_exp.bin", "wb") as f:
        f.write(y.astype(np.int32).tobytes())

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate data for y = k*x + a.")
    parser.add_argument("--R", type=int, required=True, help="Number of lanes per beat")
    parser.add_argument("--K", type=int, required=True, help="Number of beats")
    parser.add_argument("--C", type=int, required=True, help="Unused here; kept for flow compatibility")
    parser.add_argument("--DIR", type=str, required=True, help="Full directory path to save data")
    args = parser.parse_args()

    main(args.R, args.K, args.C, args.DIR)
