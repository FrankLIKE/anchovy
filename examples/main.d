/*
Copyright (c) 2013 Andrey Penechko

Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license the "Software" to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/

module main;

import core.cpuid;
import std.algorithm;
import std.conv;
import std.datetime;
import std.file;
import std.random;
import std.stdio;
import std.utf;

import derelict.opengl3.gl3;

import anchovy.graphics.windows.glfwwindow;
import anchovy.graphics.texture;
import anchovy.graphics.shaderprogram;
import anchovy.graphics.renderers.ogl3renderer;

import anchovy.graphics.font.fontmanager;
import anchovy.graphics.font.textureatlas;

import anchovy.gui.all;
import fpshelper;
import anchovy.gui.timermanager;

import anchovy.utils.string : ZToString;
import anchovy.gui.behaviors.defaultbehaviors;
import anchovy.gui.layouts.linearlayout;

import anchovy.gui.templateparser;
import anchovy.gui.widgettemplate;

version(linux)
{
	pragma(lib, "dl");
}

class GuiTestWindow : GlfwWindow
{
	void run(in string[] args)
	{
		load(args);
		double lastTime = glfwGetTime();
		double newTime;
		while(running)
		{	
			processEvents();
			newTime = glfwGetTime();
			//writeln(newTime);
			update(newTime - lastTime);
			lastTime = newTime;

			draw();
			swapBuffer;
			fpsHelper.sleepAfterFrame(lastTime - glfwGetTime());
		}
	}

	void update(double dt)
	{
		fpsHelper.update(dt);
		timerManager.updateTimers(glfwGetTime());
		context.update(dt);
	}
	
	string[] getHardwareInfo()
	{
		return [
			"CPU vendor: " ~ vendor,
			"CPU name: " ~ processor,
			"Cores: " ~ to!string(coresPerCPU),
			"Threads: " ~ to!string(threadsPerCPU),
			"CPU chache levels: " ~ to!string(cacheLevels),
			"GPU vendor: " ~ ZToString(glGetString(GL_VENDOR)),
			"Renderer: " ~ ZToString(glGetString(GL_RENDERER)),
			"OpenGL version: " ~ ZToString(glGetString(GL_VERSION)),
			"GLSL version: " ~ ZToString(glGetString(GL_SHADING_LANGUAGE_VERSION)),
		];
	}

	void load(in string[] args)
	{
		foreach(item; getHardwareInfo())
			writeln(item);
		writeln("========");
		dstring cyrillicChars = "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюяє"d;

		//-------------- Setting renderer --------------
		renderer = new Ogl3Renderer(this);
		renderer.setClearColor(Color(50, 10, 45));

		//-------------- Skin loading --------------
		string graySkinSource = cast(string)read("skingray.json");
		auto skinParser = new JsonGuiSkinParser;
		graySkin = skinParser.parse(graySkinSource);

		//-------------- Gui renderer --------------
		guiRenderer = new SkinnedGuiRenderer(renderer, graySkin);
		guiRenderer.fontManager.charCache ~= cyrillicChars;
		graySkin.loadResources(guiRenderer);

		fpsHelper.maxFps = 120;
		timerManager = new TimerManager(delegate double(){return glfwGetTime();});

		//-------------- Template loading --------------

		auto templateParser = new TemplateParser;
		auto templateManager = new TemplateManager(templateParser);
		templateManager.parseFile("appLayout.sdl");

		//-------------- Setting context --------------
		context = new GuiContext(guiRenderer, timerManager, templateManager, graySkin);
		context.setClipboardStringCallback = (dstring newStr) => setClipboard(to!string(newStr));
		context.getClipboardStringCallback = delegate dstring(){return to!dstring(getClipboard());};
		context.attachDefaultBehaviors();

		//-------------- Creating widgets --------------------
		auto mainLayer = context.createWidget("widget");
			mainLayer["name"] = "mainLayer";
			mainLayer["isVisible"] = false;
			mainLayer.setProperty!("layout")(cast(ILayout)new VerticalLayout);
		context.addRoot(mainLayer);

		auto button1 = context.createWidget("button", mainLayer);
			button1["name"] = "button1";
			button1.setProperty!"prefSize"(ivec2(50, 50));
			button1.setProperty!"position"(ivec2(20, 20));
			button1.setProperty!"caption"("Click me!");
			button1.addEventHandler(delegate bool(Widget widget, PointerClickEvent event){
				widget["caption"] = to!dstring(event.pointerPosition);
				writeln("Clicked at ", event.pointerPosition);
				return true;
			});
			button1.addEventHandler(delegate bool(Widget widget, PointerLeaveEvent event)
											{widget["caption"] = "Click me!";return true;});

		auto button = context.createWidget("widget", mainLayer);
			button.setProperty!"prefSize"(ivec2(50, 50));
			button.setProperty!"vexpand"(true);
			button.setProperty!"style"("button");
		
		button = context.createWidget("widget", mainLayer);
			button.setProperty!"prefSize"(ivec2(50, 50));
			button.setProperty!"hexpand"(true);
		
		auto container = context.createWidget("widget", mainLayer);
			container.setProperty!("layout")(cast(ILayout)new HorizontalLayout);
			container.setProperty!"prefSize"(ivec2(50, 50));
			container.setProperty!"hexpand"(true);
			container.setProperty!"vexpand"(true);

		templateManager.parseString(`
					template:mybutton extends="button" {
						tree "vexpand" style="button"
					}`);
		button = context.createWidget("mybutton", container);
			button.setProperty!"prefSize"(ivec2(50, 50));
			button.setProperty!"vexpand"(true);

		writeln(templateManager.templates);

		//--------------- Rendering settings---------------------------
		renderer.enableAlphaBlending();
		glEnable(GL_SCISSOR_TEST);
	}

	void draw()
	{
		guiRenderer.setClientArea(Rect(0, 0, width, height));
		glClear(GL_COLOR_BUFFER_BIT);

		renderer.setColor(Color4f(1 ,0.5,0,0.5));
		renderer.fillRect(0, 0, 50, 50);
		renderer.setColor(Color(255, 255, 255));
		renderer.drawTexRect(width - 255, 0, 256, 256, 0, 0, 256, 256, guiRenderer.getFontTexture);

		context.draw();

		glUseProgram(0);
	}

	override bool quit()
	{
		running = false;
		return true;
	}

	override void windowResized(in uint newWidth, in uint newHeight)
	{
		try
		{
			reshape(newWidth, newHeight);
			context.size = ivec2(newWidth, newHeight);
		}
		catch(Exception e)
		{
		}
	}

	override void mousePressed(in uint mouseButton)
	{
		try
		{
			context.pointerPressed(getMousePosition, cast(PointerButton)mouseButton);
		}
		catch(Exception e)
		{
		}
	}

	override void mouseReleased(in uint mouseButton)
	{
		try
		{
			context.pointerReleased(getMousePosition, cast(PointerButton)mouseButton);
		}
		catch(Exception e)
		{
		}
	}

	override void mouseMoved(in int newX, in int newY)
	{
		try
		{
			ivec2 newPos = ivec2(newX, newY);
			ivec2 deltaPos = newPos - pointerPosition;
			pointerPosition = newPos;
			context.pointerMoved(newPos, deltaPos);
		}
		catch(Exception e)
		{
		}
	}

	KeyModifiers getCurrentKeyModifiers()
	{
		KeyModifiers modifiers;
		if (isKeyPressed(KeyCode.KEY_LEFT_SHIFT) || isKeyPressed(KeyCode.KEY_RIGHT_SHIFT))
			modifiers |= KeyModifiers.SHIFT;
		if (isKeyPressed(KeyCode.KEY_LEFT_CONTROL) || isKeyPressed(KeyCode.KEY_RIGHT_CONTROL))
			modifiers |= KeyModifiers.CONTROL;
		if (isKeyPressed(KeyCode.KEY_LEFT_ALT) || isKeyPressed(KeyCode.KEY_RIGHT_ALT))
			modifiers |= KeyModifiers.ALT;
		return modifiers;
	}

	override void keyPressed(in uint keyCode)
	{
		try
		{
			if (keyCode == GLFW_KEY_ESCAPE)
			{
				running = false;
				return;
			}
			context.keyPressed(cast(KeyCode)keyCode, getCurrentKeyModifiers());
		}
		catch(Exception e)
		{
		}
	}

	override void keyReleased(in uint keyCode)
	{
		try
		{
			context.keyReleased(cast(KeyCode)keyCode, getCurrentKeyModifiers());
		}
		catch(Exception e)
		{
		}
	}

	override void charReleased(in dchar unicode)
	{
		try
		{
			context.charEntered(unicode);
		}
		catch(Exception e)
		{
		}
	}

	GuiContext context;
	ivec2 pointerPosition;
	GuiSkin graySkin;

	TimerManager timerManager;

	Widget fpsLabel;

	uint testTexture;

	IRenderer renderer;
	IGuiRenderer guiRenderer;

	bool running = true;
	FpsHelper fpsHelper;
}

void main(string[] args)
{
	GuiTestWindow window;
		window = new GuiTestWindow();
		window.init(512, 512, "Gui testing");
		window.run(args);
	window.releaseWindow;
}