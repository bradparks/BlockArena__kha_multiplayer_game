package;

import kha.Assets;
import kha.Color;
import kha.Font;
import kha.Framebuffer;
import kha.input.Keyboard;
import kha.Key;
import kha.network.Session;
import kha.Scheduler;
import kha.System;

class BlockArena {
	private var session: Session;
	private var waiting: Bool;
	private var font: Font;
	
	private var blocks: Array<Block> = new Array();
	
	public function new() {
		waiting = true;
		Assets.loadEverything(onLoaded);
	}
	
	private function onLoaded(): Void {
		font = Assets.fonts.DejaVuSansMono;
		System.notifyOnRender(render);
		Scheduler.addTimeTask(update, 0, 1 / 60);
    
		// Initialize the network session
		// Note: If you do not want to use a hardcoded server address ask the user beforehand
		var serverAddress = "localhost";
		session = new Session(2, serverAddress, 6789);

		// Wait for enough players to connect
		session.waitForStart(startSession);
	}
	
	private function startSession(): Void {
		waiting = false;
		
		// Create game objects and add them to the session
		var block = new Block(100, 100);
		blocks.push(block);
		session.addEntity(block);

		block = new Block(500, 100);
		blocks.push(block);
		session.addEntity(block);
		
		// Define controls and add input device to the session
		// Note: Use session.me.id to identify the local player
		Keyboard.get().notify(
			function (key: Key, char: String) {
				if (waiting) return;
				switch (key) {
				case LEFT:
					blocks[session.me.id].left = 2;
				case RIGHT:
					blocks[session.me.id].right = 2;
				default:
				}
			},
			function (key: Key, char: String) {
				if (waiting) return;
				switch (key) {
				case LEFT:
					blocks[session.me.id].left = 0;
				case RIGHT:
					blocks[session.me.id].right = 0;
				default:
				}	
			}
		);
		session.addController(Keyboard.get());
	}
	
	private function update(): Void {
		for (block in blocks) {
			block.sx = block.right - block.left;
			block.sy = 7.5;
			block.x += block.sx;
			block.y += block.sy;
			if (block.y > System.windowHeight()) block.y -= System.windowHeight() + 100;
		}
	}
	
	public function render(frame: Framebuffer): Void {
		var g = frame.g2;
		g.begin(true, Color.Black);

		if (waiting) {
			g.color = Color.White;
			g.font = font;
			g.fontSize = 20;

			var text = "Waiting";
			g.drawString(text, System.windowWidth() / 2 - font.width(g.fontSize, text) / 2, System.windowHeight() / 2 - font.height(g.fontSize) / 2);
		}
		else {
			g.color = Color.White;
			g.font = font;
			g.fontSize = 20;

			g.drawString("" + Scheduler.time(), 10, 10);
			g.drawString("Ping: " + Std.int(session.ping * 1000), 10, 35);
			
			for (block in blocks) {
				block.render(g);
			}
		}

		g.end();
	}
}
