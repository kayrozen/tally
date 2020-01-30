# tally
A wifi-powered tally system for the Roland VR4-HD AV Mixer

Based on https://medium.com/@richmans/using-nodemcu-for-a-camera-light-58ef6d26a405

Mods to add : 
- GPIO pinout hookups to DB15 instead to DB9 https://static.roland.com/assets/media/pdf/VR-4HD_reference_v2_eng01_W.pdf
- Add WS2812b library to control RGB LEDS instead
- Add wifi connection led indications (connecting : flash yellow, connected: blink green twice, on air : solid red
