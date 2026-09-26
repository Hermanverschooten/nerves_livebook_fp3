import Config

# Boot order: nerves_ai runs the first-boot F2FS resize (which briefly
# unmounts /root) before Livebook starts writing to /data.
config :shoehorn,
  init: [:nerves_runtime, :nerves_pack, :nerves_ai],
  app: Mix.Project.config()[:app]

# Advance the system clock on devices without a real-time clock.
config :nerves, :erlinit, update_clock: true

# SSH access for `mix upload` and IEx. Keys come from the build machine.
keys =
  System.user_home!()
  |> Path.join(".ssh/id_{rsa,ecdsa,ed25519}.pub")
  |> Path.wildcard()

if keys == [] do
  IO.warn("No SSH public keys in ~/.ssh: `mix upload` and ssh won't work on this firmware.")
end

config :nerves_ssh, authorized_keys: Enum.map(keys, &File.read!/1)

# Advertise nerves.local (and the unique nerves-XXXX.local hostname).
# With several phones on one network, drop "nerves" and use the unique
# names instead.
config :mdns_lite,
  hosts: [:hostname, "nerves"],
  ttl: 120,
  services: [
    %{protocol: "ssh", transport: "tcp", port: 22},
    %{protocol: "http", transport: "tcp", port: 4000}
  ]

# Cellular data is optional: the APN depends on the SIM, so it's only
# configured when FP3_APN is set at build time (e.g. FP3_APN=internet.be).
apn = System.get_env("FP3_APN")

modem =
  if apn do
    [
      {"rmnet0",
       %{
         type: VintageNetQMI,
         vintage_net_qmi: %{
           service_providers: [%{apn: apn}],
           provision_uim: true,
           ip_method: :qmi_profile,
           rmnet_child: %{parent: "rmnet_ipa0", mux_id: 1}
         }
       }}
    ]
  else
    []
  end

# Networking: USB gadget ethernet to the laptop, plus wired ethernet
# (USB-C adapter) and optionally the modem.
config :vintage_net,
  regulatory_domain: "BE",
  power_managers:
    if(apn, do: [{Fp3Modem.PowerManager, [ifname: "rmnet0", watchdog_timeout: 120_000]}], else: []),
  config:
    [
      {"usb0", %{type: VintageNetDirect}},
      {"eth0", %{type: VintageNetEthernet, ipv4: %{method: :dhcp}}}
    ] ++ modem

# ALSA routing for the FP3+ loudspeaker (TAS2557 amp on QUIN MI2S).
# The original FP3's amp needs different controls.
config :ex_audio,
  card: 0,
  mixer: [
    {"QUIN_MI2S_RX Audio Mixer MultiMedia1", :on},
    {"Speaker Switch", :on}
  ]

# Livebook's web endpoint on port 4000 on every interface.
#
# Not a real secret: this is a public repo with authentication
# disabled, so secret_key_base protects nothing here — Phoenix just
# requires >= 64 bytes. Derived (not hardcoded) so it stays visibly
# non-sensitive and builds stay deterministic.
config :livebook, :iframe_port, 4001

config :livebook, LivebookWeb.Endpoint,
  url: [host: "nerves.local", port: 4000],
  http: [port: 4000, ip: {0, 0, 0, 0}],
  server: true,
  secret_key_base:
    :sha512
    |> :crypto.hash("nerves_livebook_fp3-not-a-secret-key-base")
    |> Base.encode64()
