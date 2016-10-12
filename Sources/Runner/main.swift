import Foundation
import SwiftDiscord

let queue = DispatchQueue(label: "Async Read")
let writeQueue = DispatchQueue(label: "Async Write")
let client = DiscordClient(token: "")

var writer: FileHandle!
var youtube: Process!

func readAsync() {
	queue.async {
		guard let input = readLine(strippingNewline: true) else { return readAsync() }

        if input == "quit" {
            client.disconnect()
        } else if input == "testget" {
        	client.getMessages(for: "232184444340011009", options: [.limit(3)]) {messages in
        		print(messages)
        	}
        } else if input == "join" {
        	client.joinVoiceChannel("201533018215677954") {message in
        		print(message)
        	}
        } else if input.hasPrefix("play") {
        	let music = FileHandle(forReadingAtPath: "../../Music/testing.mp3")!
        	writeQueue.async {
        		let data = music.readDataToEndOfFile()

        		print("read \(data)")
        		writer.write(data)
        	}
        	// client.voiceEngine?.sendVoiceData(music.readDataToEndOfFile())
        } else if input == "new" {
            // writer.closeFile()
            youtube?.terminate()
            client.voiceEngine?.requestNewWriter()
        } else if input.hasPrefix("youtube") {
        	let link = input.components(separatedBy: " ")[1]
        	youtube = Process()

        	youtube.launchPath = "/usr/local/bin/youtube-dl"
        	youtube.arguments = ["-f", "bestaudio", "-q", "-o", "-", link]
        	youtube.standardOutput = writer
        	
        	youtube.launch()
        } else if input == "silence" {
            // client.voiceEngine?.sendVoiceData(Data(bytes: [0xF8, 0xFF, 0xFE, 0xF8, 0xFF, 0xFE, 0xF8, 0xFF, 0xFE, 
            //     0xF8, 0xFF, 0xFE, 0xF8, 0xFF, 0xFE]))
        } else {
        	client.sendMessage(input, to: "232184444340011009")
        }

        readAsync()
	}
}

print("Type 'quit' to stop")
readAsync()

client.on("engine.disconnect") {data in
	print("Engine died, exiting")
	exit(0)
}

client.on("connect") {data in
	print("connect")
	// print(client.guilds)
}

client.on("voiceEngine.writeHandle") {data in
	guard let writeHandle = data[0] as? FileHandle else { fatalError() }

	print("Got handle")

	writer = writeHandle
}

client.on("message") {data in
	guard let message = data[0] as? DiscordMessage else { fatalError("Didn't get message in message event") }

	print(message)
}

client.connect()

CFRunLoopRun()