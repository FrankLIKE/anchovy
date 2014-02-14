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

module anchovy.graphics.font.font;

import std.stdio;
import std.string: toStringz;

import derelict.freetype.ft;

import anchovy.core.types;
import anchovy.graphics.texture;
import anchovy.graphics.bitmap;

import anchovy.graphics.font.fterrors;
import anchovy.graphics.font.textureatlas;

struct Glyph
{
	uvec2 atlasPosition;
	GlyphMetrics metrics;
}

struct GlyphMetrics
{
	uint width;
	uint height;
	int offsetX;
	int offsetY;
	uint advanceX;
	uint advanceY;
}

class Font
{
public:

	this(in string filename, TextureAtlas texAtlas, in dstring chars, in uint size)
	{
		FT_Library	library;
		FT_Face		face;

		try
		{
			checkFtError(
				FT_Init_FreeType(&library));
			checkFtError(
				FT_New_Face(library, toStringz(filename), 0, &face));
			checkFtError(
				FT_Select_Charmap(face, FT_ENCODING_UNICODE));
			checkFtError(
				//FT_Set_Char_Size(face, cast(int)(size*64), 0, 72, 0));
				FT_Set_Pixel_Sizes(face, 0, size));
		}
		catch(FreeTypeException e)
		{
			writeln("Can not load font '"~filename~"'");
			writeln(e.msg);
		}

		loadGlyphs(chars, library, face, texAtlas, size);
		_ascender = face.ascender/64;
		_descender = face.descender/64;
		_height = face.height/64;
		_size = size;
		FT_Done_Face(face);
		FT_Done_FreeType(library);
	}

	uint height() @property const
	{
		return _height;
	}
	
	uint size() @property const
	{
		return _size;
	}
	
	uint lineGap() @property const
	{
		return _lineGap;
	}
	
	uint ascender() @property const
	{
		return _ascender;
	}
	
	uint descender() @property const
	{
		return _descender;
	}

	int verticalOffset() @property const
	{
		return _verticalOffset;
	}

	void verticalOffset(int value) @property const
	{
		_verticalOffset = value;
	}

	uint getKerning(in dchar leftGlyph, in dchar rightGlyph)
	{
		uint[dchar] rightGlyps = *(leftGlyph in kerningTable);
		uint kerning = *(rightGlyph in rightGlyps);
		return kerning;
	}

	Glyph* getGlyph(in dchar chr)
	{
		if (auto glyph = chr in glyphs)
		{
			return glyph;
		}
		else
			return '?' in glyphs;//TODO: Add loading for nonexisting glyphs
	}

private:

	private void loadGlyphs(in dstring chars, in FT_Library library, ref FT_Face face, TextureAtlas atlas, in uint size)
	{
		if (chars.length == 0) return;

		FT_Bitmap		ftBitmap;
		FT_Error		ftError;
		FT_Glyph		ftGlyph;
		FT_UInt			ftGlyphIndex;
		FT_GlyphSlot	ftGlyphSlot;

		uint missed = 0;
		Glyph currentGlyph;

		foreach(dchar chr; chars)
		{
			if (chr in glyphs) continue;
			//checkFtError(
				//FT_Set_Char_Size(face, cast(int)(size*64), 0, 96, 0));
				//FT_Set_Pixel_Sizes(face, 0, size));
			checkFtError(
				FT_Load_Char(face, chr, FT_LOAD_RENDER));
			currentGlyph.metrics = loadGlyphMetrics(face);
			currentGlyph.atlasPosition = putBitmapToAtlas(atlas,
			                                              face.glyph.bitmap,
			                                              currentGlyph.metrics.width,
			                                              currentGlyph.metrics.height);
			glyphs[chr] = currentGlyph;
		}
		glyphs.rehash;
	}

	private uvec2 putBitmapToAtlas(ref TextureAtlas atlas, in FT_Bitmap ftBitmap, in uint width, in uint height)
	{
		uvec2 pos = atlas.insert(width, height);
		Bitmap atlasBitmap = atlas.getBitmap();
		atlasBitmap.putCustomRect(pos, ftBitmap.buffer, 1, width, height);

		return pos;
	}

	private GlyphMetrics loadGlyphMetrics(in FT_Face face)
	{
		GlyphMetrics gm;
		FT_Glyph_Metrics ftgm = face.glyph.metrics;
		gm.width	= ftgm.width / 64;
		gm.height	= ftgm.height / 64;
		gm.offsetX	= ftgm.horiBearingX / 64;
		gm.offsetY	= ftgm.horiBearingY / 64;
		gm.advanceX	= ftgm.horiAdvance / 64;
		gm.advanceY	= ftgm.vertAdvance / 64;
		return gm;
	}

private:

	uint _height;
	uint _size;
	uint _lineGap;
	uint _ascender;
	uint _descender;
	int  _verticalOffset; // Can be used to manually adjust vertical position of text.

	Glyph[dchar] glyphs;
	//Glyph[dchar] boldGlyphs;
	//Glyph[dchar] italicGlyphs;

	/**
	 * Usage:
	 * -----
	 * uint kern = kerningTable[left][right];
	 * kerningTable[left][right] = kern;
	 * -----
	 */
	uint[dchar][dchar] kerningTable;  //Not yet implemented
	bool kerningEnabled = true;
}

