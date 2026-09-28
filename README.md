# nerves_livebook_fp3

> ### ⚠️ Very early work — built for a workshop, not for production
>
> Written for the **Goatmire Elixir workshop** on running Nerves on
> Fairphone 3 hardware. There are no stability guarantees and APIs will
> change without notice.

Workshop firmware for the Fairphone 3 and 3+. It boots straight into a
Livebook with the [`nerves_ai`](https://github.com/mlainez/nerves_ai)
edge-AI stack and the Fairphone 3 hardware libraries loaded.

## At workshop time

1. Power on the phone and connect it to your laptop over USB.
2. Open `http://nerves.local:4000` (or `http://nerves-XXXX.local:4000`
   when several phones share a network).
3. Open a notebook and evaluate it.

## Notebooks

| Notebook | What it covers |
|---|---|
| `00_introduction.livemd` | The phone, what Nerves can use, boot chain, partitions, first-time flashing |
| `01_led_flash_vibrator.livemd` | RGB notification LED, flashlight, vibrator |
| `02_sensors.livemd` | Accelerometer, gyroscope, magnetometer, proximity |
| `03_cameras.livemd` | Photos from both cameras, H.264 video stream |
| `04_nfc.livemd` | Detect NFC tags and contactless cards |
| `05_gps.livemd` | Satellites in view and position fixes |
| `06_modem.livemd` | IMEI, operating mode, home network, signal strength |
| `07_llm_chat.livemd` | TinyLlama chat on the phone's CPU |
| `08_audio.livemd` | Loudspeaker: tones, melodies, WAV files |
| `09_screen_touch_buttons.livemd` | Draw on the screen, touch input, volume and power buttons |

Notebooks ship in `priv/samples` and are copied to
`/data/livebook/notebooks` at boot, then starred so they appear on
Livebook's home page. A notebook that's already on `/data` is never
overwritten, so attendee edits survive reboots and firmware updates.

The hardware notebooks use these libraries, all started at boot:
`ex_qcom_smgr` (sensors), `fp3_camera`, `ex_nfc`, `ex_location` (GPS,
and the QMI client the modem notebook uses), plus the kernel's LED
interface and the system's `rumble` tool for the vibrator, and
`input_event` for the touchscreen and buttons. `ex_audio`
sets up the loudspeaker route and `ex_qbootctl` marks each boot slot
successful. The microphone and earpiece aren't supported by the kernel
yet.

## Models

Models are too large for the firmware image (the root filesystem is
250 MiB), and nothing downloads them at boot. Each AI notebook fetches
the model it needs with `NervesModelHub.ensure_one/2` the first time it
runs: the phone downloads it from Hugging Face over Wi-Fi into
`/data/models`, checks its SHA-256, and reuses it afterwards. The notebooks include a
cell to connect the phone to Wi-Fi.

## For the workshop organiser

### Prerequisites

* Erlang/OTP 29.1.1 and Elixir 1.20.4 (see `.tool-versions`), matching
  the official Nerves systems, and the `nerves_bootstrap` archive.
* A Rust toolchain with the `aarch64-unknown-linux-gnu` target
  (`rustup target add aarch64-unknown-linux-gnu`). The `arm_ai` NIF has
  no precompiled release, so it is always built from source.
* An SSH public key in `~/.ssh`, which is baked into the firmware for
  `mix upload` and SSH access.

### Build the firmware

```sh
export MIX_TARGET=nerves_system_fp3
mix deps.get
mix firmware
```

The first build compiles `nerves_system_fp3` from source, which takes a
long time.

Cellular data is off unless you pass the SIM's APN at build time, for
example `FP3_APN=internet.be mix firmware`. That adds the modem's QMI
interface and `Fp3Modem.PowerManager` to the network config.

For a workshop venue, build with its Wi-Fi so every phone joins it on
first boot: `FP3_WIFI_SSID=venue FP3_WIFI_PASSPHRASE=secret mix firmware`
(leave out the passphrase for an open network). The credentials end up
in the image. People can pick another network with the Wi-Fi notebook.

### Flash a device

The first install needs lk2nd on the boot partition and the firmware
image on `userdata`. Follow the flashing steps in the
[`nerves_system_fp3` README](https://github.com/mlainez/nerves_system_fp3#flashing),
using the image from:

```sh
mix firmware.image    # writes ./nerves_livebook_fp3.img
```

After that, update over the network:

```sh
mix upload
```

## What's running on the device

```
nerves_livebook_fp3
├── nerves_system_fp3   kernel, bootloader glue, daemons (rmtfs, qbootctl, …)
├── nerves_ai           the AI stack
│   ├── arm_ai          Rust NIF: candle LLM + Whisper, tract ONNX, NEON kernels
│   ├── nx_arm          Nx backend and Defn compiler on arm_ai
│   ├── nx_primitives   FFT, embeddings, int8 matmul/conv
│   ├── infer_llm       Whisper STT, KV cache, sampling
│   ├── infer_vision    YOLO, generic ONNX, image preprocessing
│   ├── infer_audio     audio decode / resample / WAV
│   ├── cpu_governor    scoped performance governor
│   ├── nerves_model_hub  model downloads
│   └── nerves_data_resize  first-boot F2FS grow
├── ex_rmtfs, ex_remoteproc   modem storage daemon, ADSP start-up
├── ex_qcom_smgr, fp3_camera, ex_audio, ex_nfc, ex_location, ex_qbootctl
├── fp3_modem, vintage_net_qmi, qmi   cellular (only with FP3_APN)
└── livebook + kino
```

## Security

Livebook runs with authentication disabled: anyone who can reach port
4000 can run code on the phone. Only connect it to networks you trust.

Livebook 0.19.10, the current release, pins exact versions of its web
stack. `mix hex.audit` reports advisories against several of them
(Bandit, Plug, Phoenix, Req, protobuf), and they can't be overridden
without breaking Livebook's own constraints. Update Livebook when a
release with patched dependencies is available.

## License

Apache-2.0.
