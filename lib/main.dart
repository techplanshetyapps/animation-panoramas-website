
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
  
  // Parallel API Telemetry State Map
  Map<String, dynamic> _telemetryData = {
    'temperature': 0.0,
    'humidity': 0.0,
    'specimen': 'Scanning...',
    'status': 'SYNCING',
  };

  final OlapApiService _olapApiService = OlapApiService();

  @override
  void initState() {
    super.initState();
    _loadParallelTelemetry();
  }

  Future<void> _loadParallelTelemetry() async {
    setState(() => _isFetchingLive = true);
    final ecosystem = ecosystems[_currentIndex];
    
    // Executes concurrent parallel API streams (Open-Meteo & Parallel.ai)
    final data = await _olapApiService.fetchEcosystemWithParallelAI(
      ecosystem.title, 
      ecosystem.lat, 
      ecosystem.lng,
    );

    setState(() {
      _telemetryData = data;
      _isFetchingLive = false;
    });
  }

  void _goNext() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % ecosystems.length;
    });
    _loadParallelTelemetry();
  }

  void _goPrev() {
    setState(() {
      _currentIndex = (_currentIndex - 1 + ecosystems.length) % ecosystems.length;
    });
    _loadParallelTelemetry();
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

          // 2. 3D/2D Model Viewer Canvas Replacement
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

          // 3. UI Overlay & Parallel Telemetry Dashboard
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top section info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
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
                      const SizedBox(height: 12),
                      Text(
                        ecosystem.title,
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ecosystem.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9), height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ecosystem.fact,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.8)),
                      ),
                    ],
                  ),

                  // Middle: Grafana MCP & Parallel.ai Telemetry Dashboard Widget
                  GrafanaMcpDashboardWidget(
                    telemetry: _telemetryData,
                    isFetching: _isFetchingLive,
                    onRefresh: _loadParallelTelemetry,
                  ),

                  // Bottom Navigation Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _goPrev,
                        icon: const FaIcon(FontAwesomeIcons.chevronLeft, size: 12),
                        label: const Text("Prev"),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        "${_currentIndex + 1} / ${ecosystems.length}",
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton.icon(
                        onPressed: _goNext,
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
}