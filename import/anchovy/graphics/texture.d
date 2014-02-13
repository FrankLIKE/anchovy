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

module anchovy.graphics.texture;

public import derelict.opengl3.gl3;

import std.conv, std.file;
import std.stdio;
import std.string;

import anchovy.core.types;
import anchovy.graphics.glerrors;
import anchovy.graphics.bitmap;

//version = debugTexture;

enum TextureTarget : uint
{
	target1d = GL_TEXTURE_1D,
	target2d = GL_TEXTURE_2D,
	target3d = GL_TEXTURE_3D,
	targetRectangle = GL_TEXTURE_RECTANGLE,
	targetBuffer = GL_TEXTURE_BUFFER,
	targetCubeMap = GL_TEXTURE_CUBE_MAP,
	target1dArray = GL_TEXTURE_1D_ARRAY,
	target2dArray = GL_TEXTURE_2D_ARRAY,
	targetCubeMapArray = GL_TEXTURE_CUBE_MAP_ARRAY,
	target2dMultisample = GL_TEXTURE_2D_MULTISAMPLE,
	target2dMultisampleArray = GL_TEXTURE_2D_MULTISAMPLE_ARRAY,
}

enum TextureFormat : uint
{
	r = GL_RED,
	rg = GL_RG,
	rgb = GL_RGB,
	rgba = GL_RGBA,
}

class Texture
{
	this(string filename, TextureTarget target, TextureFormat format)
	{
		texTarget = target;
		texFormat = format;
		genTexture();
		loadFromFile(filename);
	}
	
	this(Bitmap textureData, TextureTarget target, TextureFormat format)
	{
		texTarget = target;
		texFormat = format;
		genTexture();
		loadFromData(textureData);
	}
	
	~this()
	{
		unload();
	}
	
	void validateBind(uint textureUnit = 0)
	{
		if (!isValid) reload();

		texUnit = GL_TEXTURE0 + textureUnit;

		glBindTexture(texTarget, glTextureHandle);
			checkGlError;
	}

	void bind(uint textureUnit = 0)
	{
		texUnit = GL_TEXTURE0 + textureUnit;

		glBindTexture(texTarget, glTextureHandle);
			checkGlError;
	}
	
	void unbind()
	{
		glBindTexture(texTarget, 0);
	}
	
	uint width()
	{
		return bitmap.width;
	}

	uint height()
	{
		return bitmap.height;
	}
	
	ref const(ubyte[]) data()
	{
		return bitmap.data;
	}

	private void reload()
	{
		bind;

		if (bitmap.width != lastWidth || bitmap.height != lastHeight)
		{
			glTexImage2D(texTarget, 0, texFormat, bitmap.width, bitmap.height, 0, texFormat, GL_UNSIGNED_BYTE, null);
				checkGlError;
			glTexImage2D(texTarget, 0, texFormat, bitmap.width, bitmap.height, 0, texFormat, GL_UNSIGNED_BYTE, bitmap.data.ptr);
				checkGlError;

			lastWidth = bitmap.width;
			lastHeight = bitmap.height;
		}
		else
		{
			glTexSubImage2D(texTarget, 0, 0, 0, bitmap.width, bitmap.height,  texFormat, GL_UNSIGNED_BYTE, bitmap.data.ptr);
				checkGlError;
		}
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
			checkGlError;
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
			checkGlError;
		unbind;

		isValid = true;
	}

	void invalidate()
	{
		isValid = false;
	}

	void onBitmapChanged()
	{
		invalidate();
	}
	
	/////////////////
	//Private methods
	/////////////////
	
	private void genTexture()
	{
		glGenTextures(1, &glTextureHandle);
			checkGlError;
	}
	
	/// Loads image from file in RGBA8 format
	private void loadFromFile(string filename)
	{
		if (!exists(filename)) throw new Exception("File not found: " ~ filename);

		if (bitmap)
		{
			bitmap.dataChanged.disconnect(&onBitmapChanged);
		}

		bitmap = createBitmapFromFile(filename);

		bitmap.dataChanged.connect(&onBitmapChanged);

		invalidate();
	}
	
	private void loadFromData(Bitmap textureData)
	{
		if (bitmap)
		{
			bitmap.dataChanged.disconnect(&onBitmapChanged);
		}

		this.bitmap = textureData;
		bitmap.dataChanged.connect(&onBitmapChanged);

		invalidate();
	}
	
	private void uploadToVideo()
	{
		debug writeln("uploadToVideo");
		bind;
		glTexImage2D(GL_TEXTURE_2D, 0, texFormat, bitmap.width, bitmap.height, 0, texFormat, GL_UNSIGNED_BYTE, bitmap.data.ptr);
			checkGlError;
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
			checkGlError;
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
			checkGlError;
		unbind;

		lastWidth = bitmap.width;
		lastHeight = bitmap.height;
	}
	
	private void unload()
	{
		glDeleteTextures(1, &glTextureHandle);
	}
	
private:
	TextureFormat texFormat;
	uint glTextureHandle;
	TextureTarget texTarget;
	uint lastWidth;
	uint lastHeight;
	bool isValid = false;

	uint texUnit = 0;
	Bitmap	bitmap;
}