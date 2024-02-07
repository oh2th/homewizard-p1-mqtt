
# HomeWizard P1 MQTT Publisher

Poll the HomeWizard P1 local API and publish the data JSON to a MQTT topic.

## Hardware prerequisites

- [Energymeter with P1 (HAN) -port](https://ruuvi.com/)
- [HomeWizard Wi-fi P1 Meter](https://www.homewizard.com/)

## Software prerequisites

- Some MQTT broker like Mosquitto running somewhere.
- Perl libraries LWP::UserAgent, Net::MQTT::Simple, JSON::PP

## Configure the P1 Meter

Using HomeWizard Energy app go to the device settings and enable the Local API. When enabled test with a browser by going to `http://{IP address}/api`. You should receive a JSON messahe like this:

```text
{
  "product_type": "HWE-P1",
  "product_name": "P1 Meter",
  "serial": "3c39e7aabbcc",
  "firmware_version": "2.11",
  "api_version": "v1"
}
```

If not, there is an access problem from your browser to the P1-adapter. Check your connections and the setting in the HomeWizard Energy app.

## Configuring the script

Sample configuration file is in the sample directory. Copy it to the source root directory and edit it to your needs.

### config.txt

```text
homewizard 192.168.0.200
mqtthost   test.mosquitto.org:1883
username   test
password   test
topic      homewizard/energy
interval   60
```

Note! the password is not encrypted and is sent in the clear as SSL is not implemented for now.

# Sample data on the broker

## The JSON messages sent to the broker

The script sends every retrieved data JSON as-is to the given MQTT topic. It also calculates energy import / export from the previous value. Useful for InfluxDB/Grafana usage for time series data. For every `total_power_(import|export)(_t1|_t2|_t3|_t4)_kwh` a `interval_power_(import|export)(_t1|_t2|_t3|_t4)_w` is evaluated. This is the amount of watts imported or exported since the last known good value. This allows for any interval to be used.

### Sample JSON message sent to the topic

Content depends on the energy meter and what it makes available.

```text
{
  "wifi_ssid": "My Wi-Fi",
  "wifi_strength": 100,
  "smr_version": 50,
  "meter_model": "ISKRA  2M550T-101",
  "unique_id": "00112233445566778899AABBCCDDEEFF",
  "active_tariff": 2,
  "total_power_import_kwh": 13779.338,
  "total_power_import_t1_kwh": 10830.511,
  "total_power_import_t2_kwh": 2948.827,
  "total_power_export_kwh": 0,
  "total_power_export_t1_kwh": 0,
  "total_power_export_t2_kwh": 0,
  "active_power_w": -543,
  "active_power_l1_w": -676,
  "active_power_l2_w": 133,
  "active_power_l3_w": 0,
  "active_current_l1_a": -4,
  "active_current_l2_a": 2,
  "active_current_l3_a": 0,
  "voltage_sag_l1_count": 1,
  "voltage_sag_l2_count": 1,
  "voltage_sag_l3_count": 0,
  "voltage_swell_l1_count": 0,
  "voltage_swell_l2_count": 0,
  "voltage_swell_l3_count": 0,
  "any_power_fail_count": 4,
  "long_power_fail_count": 5,
  "total_gas_m3": 2569.646,
  "gas_timestamp": 210606140010,
  "gas_unique_id": "FFEEDDCCBBAA99887766554433221100",
  "active_power_average_w": 123.000,
  "montly_power_peak_w": 1111.000,
  "montly_power_peak_timestamp": 230101080010,
  "external": []
}
```

# Disclaimer

This script is based on my personal needs and has only been tested based on that.

# References

- [HomeWizard API](https://api-documentation.homewizard.com/)
