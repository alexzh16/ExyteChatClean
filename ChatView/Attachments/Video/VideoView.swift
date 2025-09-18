import SwiftUI
import AVKit

struct VideoView: View {
    @EnvironmentObject var mediaPagesViewModel: FullscreenMediaPagesViewModel
    @Environment(\.chatTheme) private var theme

    @StateObject var viewModel: VideoViewModel
    @State private var playbackTime: Double = 0.0
    @State private var showPlaybackSpeedMenu = false

    var body: some View {
        ZStack(alignment: .top) {
            Group {
                if let player = viewModel.player, viewModel.status == .readyToPlay {
                    content(for: player)
                } else {
                    ActivityIndicator()
                }
            }

            VStack {
                // Кнопка для отображения меню с выбором скорости воспроизведения
                Button(action: {
                    showPlaybackSpeedMenu.toggle()
                }) {
                    Image(systemName: "speedometer")
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .clipShape(Circle())
                        .foregroundColor(.white)
                }
                .popover(isPresented: $showPlaybackSpeedMenu) {
                    VStack {
                        Text("Select Playback Speed")
                            .font(.headline)
                            .padding()

                        HStack {
                            ForEach([0.5, 1.0, 1.5, 2.0], id: \.self) { rate in
                                Button(action: {
                                    mediaPagesViewModel.setPlaybackRate(Float(rate))
                                    viewModel.player?.rate = mediaPagesViewModel.playbackRate
                                    showPlaybackSpeedMenu = false
                                }) {
                                    Text("\(rate)x")
                                        .padding()
                                        .background(mediaPagesViewModel.playbackRate == Float(rate) ? Color.blue : Color.gray)
                                        .clipShape(Circle())
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding()
                    }
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 10)
                    .frame(width: 250)
                }
                
                Spacer()
                
                // Отображение текущего времени воспроизведения
                HStack {
                    Text("Time: \(playbackTime.formattedTime)")
                    Spacer()
                }
                .padding()
                .background(Color.black.opacity(0.7))
                .foregroundColor(.white)
            }
        }
        .contentShape(Rectangle())
        .onAppear {
            viewModel.onStart()
            addPeriodicTimeObserver()
            
            mediaPagesViewModel.toggleVideoPlaying = {
                viewModel.togglePlay()
            }
            mediaPagesViewModel.toggleVideoMuted = {
                viewModel.toggleMute()
            }
        }
        .onDisappear {
            viewModel.onStop()
        }
        .onChange(of: viewModel.isPlaying) { newValue, _ in
            mediaPagesViewModel.videoPlaying = newValue
        }
        .onChange(of: viewModel.isMuted) { newValue, _ in
            mediaPagesViewModel.videoMuted = newValue
        }
        .onChange(of: viewModel.status) { status, _ in
            if status == .readyToPlay {
                viewModel.togglePlay()
            }
        }
    }
    
    func content(for player: AVPlayer) -> some View {
        VideoPlayer(player: player)
    }
    
    private func addPeriodicTimeObserver() {
        guard let player = viewModel.player else { return }
        player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: .main) { time in
            playbackTime = time.seconds
        }
    }
}

private extension Double {
    var formattedTime: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
