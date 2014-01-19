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

module anchovy.graphics.windows.sdlwindow;

private{
	import std.stdio;

	import derelict.sdl2.sdl;
	import derelict.sdl2.image;
	import derelict.opengl3.gl3;

	import anchovy.core.interfaces.iwindow;

	import anchovy.utils.string;
}

class SDLWindow : IWindow
{
	override
	void init(in uint width, in uint height, in string caption)
	{
		w = width; h = height;

        DerelictSDL2.load();
        DerelictGL3.load();
        DerelictSDL2Image.load();
		 
		if(SDL_Init(SDL_INIT_VIDEO) < 0)
		{
			throw new Error("Error initializing SDL");
		}
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1);
		SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
		SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
		
		window=SDL_CreateWindow(caption.ptr, SDL_WINDOWPOS_CENTERED,
		SDL_WINDOWPOS_CENTERED, w, h, _flags);
		
		if(!window)
		{
			throw new Error("Error creating SDL window");
		}
		
		_context=SDL_GL_CreateContext(window);
		SDL_GL_SetSwapInterval(1);
		
		glClearColor(1.0, 1.0, 1.0, 1.0);
		glViewport(0, 0, w, h);
		
		DerelictGL3.reload();
	}

	override
	void reshape(in uint width, in uint height)
	{
		glViewport(0, 0, cast(GLsizei) width, cast(GLsizei) height);
	}

	override
	void releaseWindow()
	{
		SDL_GL_DeleteContext(_context);
		SDL_DestroyWindow(window);
		SDL_Quit();
	}

	override
	void setMousePosition(in int x, in int y)
	{
		SDL_WarpMouseInWindow(window, x, y);
	}

	override
	ivec2 getMousePosition()
	{
		int x, y;
		SDL_GetMouseState(&x, &y);
		return ivec2(x, y);
	}

	override
	void swapBuffer(){
		SDL_GL_SwapWindow(window);
	}

	override
	void grabMouse(){}

	override
	void releaseMouse(){}

	override
	ivec2 getSize()
	{
		int width, height;
		SDL_GetWindowSize(window, &width, &height);
		return ivec2(width, height);
	}

	override void processEvents()
	{
		assert(false);
	}

	override double getTime()
	{
		return cast(double)SDL_GetTicks() / 1000;
	}

	override bool isKeyPressed(uint key)
	{
		assert(false);
	}

	@property{
		override
		uint width(){ return w; }

		override
		uint width(in uint newWidth){ return w=newWidth;}

		override
		uint height(){ return h; }

		override
		uint height(in uint newHeight){ return h=newHeight;}
	}

	override string getClipboard()
	{
		const(char*) data = SDL_GetClipboardText();
		if (data is null) return "";
		return ZToString(data);
	}
	override void setClipboard(string newClipboardString)
	{
		assert(false);
	}

	private:
	SDL_Window 		*window;
	SDL_GLContext 	_context;
	int 	w = 800, h = 600;
	int 	_flags = SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE;
	
	bool _mouseGrabbed = false;
}