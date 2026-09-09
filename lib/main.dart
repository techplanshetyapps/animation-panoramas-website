import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'models/ecosystem.dart';
import 'data/ecosystems.dart';
import 'services/olap_service.dart';
import 'widgets/grafana_mcp_dashboard_widget.dart';
import 'widgets/ecosystem_sprite_loader.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

void main() {
  runApp(const EcosystemApp());
}

class EcosystemApp extends StatelessWidget {
  const EcosystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ecosystem Viewer',
      theme: ThemeData.dark(),
      home: const EcosystemHomeScreen(),
    );
  }
}

class EcosystemHomeScreen extends StatefulWidget {
  const EcosystemHomeScreen({super.key});

  @override
  State<EcosystemHomeScreen> createState() => _EcosystemHomeScreenState();
}

class _EcosystemHomeScreenState extends State<EcosystemHomeScreen> {
  int _currentIndex = 0;
  bool _isFetchingLive = false;
  
  // Live API States
  double? _temperature;
  double? _humidity;
  String? _sunrise;
  String? _sunset;
  String? _wildlifeSample;

  final OlapApiService _olapApiService = OlapApiService();

  @override
  void initState() {
    super.initState();
    _loadAllLiveData();
  }

  Future<void> _loadAllLiveData() async {
    setState(() => _isFetchingLive = true);
    final ecosystem = ecosystems[_currentIndex];

    // Parallel fetching for performance via OlapApiService
    final weatherFuture = _olapApiService.fetchWeather(ecosystem.lat, ecosystem.lng);
    final solarFuture = _olapApiService.fetchSolarTimes(ecosystem.lat, ecosystem.lng);
    final wildlifeFuture = _olapApiService.fetchWildlifeSample(ecosystem.lat, ecosystem.lng);

    final weatherData = await weatherFuture;
    final solarData = await solarFuture;
    final wildlifeData = await wildlifeFuture;

    setState(() {
      _temperature = weatherData?['temperature_2m']?.toDouble();
      _humidity = weatherData?['relative_humidity_2m']?.toDouble();
      _sunrise = solarData?['sunrise'] ?? 'N/A';
      _sunset = solarData?['sunset'] ?? 'N/A';
      _wildlifeSample = wildlifeData;
      _isFetchingLive = false;
    });
  }

  void _goNext() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % ecosystems.length;
    });
    _loadAllLiveData();
  }

  void _goPrev() {
    setState(() {
      _currentIndex = (_currentIndex - 1 + ecosystems.length) % ecosystems.length;
    });
    _loadAllLiveData();
  }

  @override
  Widget build(BuildContext context) {
    final ecosystem = ecosystems[_currentIndex];

    return Scaffold(
      body: Stack(
        children: [
          // 1. Dynamic Background Gradient
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [ecosystem.background.top, ecosystem.background.bottom],
              ),
            ),
          ),

          // 1.5 Transparent Animated Sprite Sheet Overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: EcosystemSpriteLoader(
                key: ValueKey(ecosystem.spritePath),
                imagePath: ecosystem.spritePath,
                totalFrames: ecosystem.spriteTotalFrames,
                columns: ecosystem.spriteColumns,
                rows: ecosystem.spriteRows,
              ),
            ),
          ),

          // 2. 3D Model Viewer Canvas
          Positioned.fill(
            child: ModelViewer(
              key: ValueKey(ecosystem.slug),
              src: ecosystem.modelPath,
              alt: ecosystem.title,
              autoRotate: true,
              cameraControls: true,
              backgroundColor: Colors.transparent,
            ),
          ),

          // 3. Vivid Half-Transparent UI Dashboard Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Title & Bio Badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              children: [
                                const FaIcon(FontAwesomeIcons.globe, size: 12, color: Colors.cyanAccent),
                                const SizedBox(width: 6),
                                Text(
                                  "LAT: ${ecosystem.lat}, LNG: ${ecosystem.lng}",
                                  style: const TextStyle(fontSize: 11, color: Colors.white70, fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              children: [
                                const FaIcon(FontAwesomeIcons.leaf, size: 12, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  ecosystem.type == "3d" ? "3D SCENE" : "2D SCENE",
                                  style: const TextStyle(fontSize: 12, letterSpacing: 0.8),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        ecosystem.title,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ecosystem.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85), height: 1.3),
                      ),
                    ],
                  ),

                  // Middle Live Telemetry Glassmorphism Dashboard Card / Grafana MCP Integration
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "BIOME LIVE TELEMETRY",
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.cyanAccent),
                            ),
                            if (_isFetchingLive)
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
                              ),
                          ],
                        ),
                        const Divider(color: Colors.white24, height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMetricItem(
                              FontAwesomeIcons.temperatureHigh,
                              "Temperature",
                              _temperature != null ? "$_temperature°C" : "---",
                            ),
                            _buildMetricItem(
                              FontAwesomeIcons.droplet,
                              "Humidity",
                              _humidity != null ? "$_humidity%" : "---",
                            ),
                            _buildMetricItem(
                              FontAwesomeIcons.sun,
                              "Solar Event",
                              _sunrise != null ? "Rise: ${_sunrise!.split('T').last.substring(0, 5)}" : "---",
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const FaIcon(FontAwesomeIcons.paw, size: 14, color: Colors.amberAccent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Sample Wildlife: ${_wildlifeSample ?? 'Scanning regional records...'}",
                                  style: const TextStyle(fontSize: 12, color: Colors.white70, fontStyle: FontStyle.italic),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Navigation Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _goPrev,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                        ),
                        icon: const FaIcon(FontAwesomeIcons.chevronLeft, size: 12),
                        label: const Text("Prev"),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        "${_currentIndex + 1} / ${ecosystems.length}",
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton.icon(
                        onPressed: _goNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                        ),
                        label: const Text("Next"),
                        icon: const FaIcon(FontAwesomeIcons.chevronRight, size: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String label, String value) {
    return Column(
      children: [
        FaIcon(icon, size: 16, color: Colors.white70),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white60)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }
}