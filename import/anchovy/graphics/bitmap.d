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

module anchovy.graphics.bitmap;

import std.file;
import std.string : toStringz;

import derelict.freeimage.freeimage;

import anchovy.core.types;
public import anchovy.utils.signal;


Bitmap createBitmapFromFile(string filename)
{
	auto bitmap = new Bitmap(4);

	bitmap.loadFromFile(filename);

	return bitmap;
}

class Bitmap
{
	this(in uint w, in uint h, in ubyte byteDepth)
	{
		this.size.x = w;
		this.size.y = h;
		this.byteDepth = byteDepth;
		data = new ubyte[w*h*byteDepth];
	}

	this(in ubyte byteDepth)
	{
		this.byteDepth = byteDepth;
	}

	uvec2 size;
	ubyte byteDepth;
	ubyte[]	data;

	Signal!() dataChanged;

	void loadFromFile(string filename)
	{
		//Automatocally detects the format(from over 20 formats!)
		FREE_IMAGE_FORMAT formato = FreeImage_GetFileType(toStringz(filename),0);
		FIBITMAP* fiimage = FreeImage_Load(formato, toStringz(filename), 0);

		if (fiimage is null) throw new Exception("Image loading failed");

		FIBITMAP* temp = fiimage;
		fiimage = FreeImage_ConvertTo32Bits(temp);

		FreeImage_Unload(temp);
	
		size.x = FreeImage_GetWidth(fiimage);
		size.y = FreeImage_GetHeight(fiimage);

		ubyte* bits = FreeImage_GetBits(fiimage);

		data = new ubyte[](size.x*size.y*4);

		foreach(i; 0 .. size.x * size.y)//Converts from BGRA to RGBA
		{
			data[i*4+0] = bits[i*4+2];
			data[i*4+1] = bits[i*4+1];
			data[i*4+2] = bits[i*4+0];
			data[i*4+3] = bits[i*4+3];
		}

		FreeImage_Unload(fiimage);
	}

	void putSubRect(in uvec2 dest, in Rect source, in Bitmap sourceBitmap)
	{
		assert(false, "putSubRect is not yet implemented");

		dataChanged.emit();
	}

	void putCustomSubRect(uvec2 dest, in Rect source, ubyte[] sourceData, in ubyte sDataByteDepth, in uint sDataWidth, in uint sDataHeight)
	in
	{
		assert(sourceData.length == sDataByteDepth * sDataWidth * sDataHeight);
		assert(byteDepth == sDataByteDepth, "Byte depth is not equal");
	}
	body
	{
		for (uint x = 0; x < source.width; ++x)
		{
			for (uint y = 0; y < source.height; ++y)
			{
				data[(y+dest.y)*size.x + x + dest.x] = sourceData[(y+source.y)*sDataWidth + x + source.x];
			}
		}

		dataChanged.emit();
	}

	void putCustomRect(uvec2 dest, in ubyte* sourceData, in ubyte sDataByteDepth, in uint sDataWidth, in uint sDataHeight)
	in
	{
		assert(byteDepth == sDataByteDepth, "Byte depth is not equal");
	}
	body
	{
		for (uint x = 0; x < sDataWidth; ++x)
		{
			for (uint y = 0; y < sDataHeight; ++y)
			{
				data[(y+dest.y)*size.x + x + dest.x] = sourceData[(y)*sDataWidth + x];
			}
		}

		dataChanged.emit();
	}
}