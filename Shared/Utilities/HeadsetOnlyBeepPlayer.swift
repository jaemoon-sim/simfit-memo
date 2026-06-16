import Foundation

#if canImport(AVFoundation) && (os(iOS) || os(watchOS))
import AVFoundation

@MainActor
public enum HeadsetOnlyBeepPlayer {
    private static var activePlayers: [AVAudioPlayer] = []

    public static func playBeep() {
        guard isHeadsetRouteActive else {
            return
        }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            return
        }

        do {
            let player = try AVAudioPlayer(data: beepWAVData)
            player.volume = 0.45
            player.prepareToPlay()
            activePlayers.append(player)
            player.play()
            trimFinishedPlayers(after: 0.4)
        } catch {
            return
        }
    }

    private static var isHeadsetRouteActive: Bool {
        let headsetPorts: Set<AVAudioSession.Port> = [
            .headphones,
            .bluetoothA2DP,
            .bluetoothHFP,
            .bluetoothLE
        ]

        return AVAudioSession.sharedInstance().currentRoute.outputs.contains { output in
            headsetPorts.contains(output.portType)
        }
    }

    private static func trimFinishedPlayers(after delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            activePlayers.removeAll { !$0.isPlaying }
        }
    }

    private static let beepWAVData: Data = {
        let sampleRate = 44_100
        let duration = 0.08
        let frequency = 1_046.5
        let sampleCount = Int(Double(sampleRate) * duration)
        let amplitude = 0.34

        var pcm = Data(capacity: sampleCount * 2)
        for sampleIndex in 0..<sampleCount {
            let progress = Double(sampleIndex) / Double(max(sampleCount - 1, 1))
            let envelope = min(1, min(progress / 0.12, (1 - progress) / 0.18))
            let sample = sin(2 * Double.pi * frequency * Double(sampleIndex) / Double(sampleRate))
            let clamped = Int16(max(-1, min(1, sample * envelope * amplitude)) * Double(Int16.max))
            var littleEndianSample = clamped.littleEndian
            pcm.append(Data(bytes: &littleEndianSample, count: MemoryLayout<Int16>.size))
        }

        return makeWAVData(
            pcmData: pcm,
            sampleRate: sampleRate,
            channelCount: 1,
            bitsPerSample: 16
        )
    }()

    private static func makeWAVData(
        pcmData: Data,
        sampleRate: Int,
        channelCount: Int,
        bitsPerSample: Int
    ) -> Data {
        var data = Data()
        let byteRate = sampleRate * channelCount * bitsPerSample / 8
        let blockAlign = channelCount * bitsPerSample / 8

        data.appendASCII("RIFF")
        data.appendUInt32LE(UInt32(36 + pcmData.count))
        data.appendASCII("WAVE")
        data.appendASCII("fmt ")
        data.appendUInt32LE(16)
        data.appendUInt16LE(1)
        data.appendUInt16LE(UInt16(channelCount))
        data.appendUInt32LE(UInt32(sampleRate))
        data.appendUInt32LE(UInt32(byteRate))
        data.appendUInt16LE(UInt16(blockAlign))
        data.appendUInt16LE(UInt16(bitsPerSample))
        data.appendASCII("data")
        data.appendUInt32LE(UInt32(pcmData.count))
        data.append(pcmData)
        return data
    }
}
#else
@MainActor
public enum HeadsetOnlyBeepPlayer {
    public static func playBeep() {}
}
#endif

private extension Data {
    mutating func appendASCII(_ string: String) {
        append(Data(string.utf8))
    }

    mutating func appendUInt16LE(_ value: UInt16) {
        var littleEndianValue = value.littleEndian
        append(Data(bytes: &littleEndianValue, count: MemoryLayout<UInt16>.size))
    }

    mutating func appendUInt32LE(_ value: UInt32) {
        var littleEndianValue = value.littleEndian
        append(Data(bytes: &littleEndianValue, count: MemoryLayout<UInt32>.size))
    }
}
