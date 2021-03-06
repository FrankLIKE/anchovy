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

module anchovy.graphics.mesh;

public import dlib.math.vector;
public import dlib.math.quaternion;
import derelict.opengl3.gl3;

/******
 * Vertex attribute storage class. For use in meshes
 *
 * Attribute will be used like this, when there is more then 1 attribute presented
 * -----
 * glVertexAttribPointer(location, elementNum, elementType, normalized, elementNum*elementSize, cast(void*)offset);
 * ---
 * or like this, when there is only one attribute in the mesh
 * -----
 * glVertexAttribPointer(location, elementNum, elementType, normalized, 0, null);
 * ---
 *****/

class Attribute
{
	uint location;
	uint elementNum;///number of 
	uint elementType;///GL_FLOAT etc
	uint elementSize;///in bytes
	uint offset;///offset from the begining of buffer
	bool normalized;
}

class Mesh
{	
	
	Vector3f		position;
	Quaternionf		orientation;
	ubyte[] 	meshData;
	GLuint		vao;
	GLuint		vbo;


	this(){
		glGenBuffers( 1, &vbo );
		glGenVertexArrays(1, &vao);
	}
	~this()
	{
		glDeleteBuffers(1, &vbo);
		glDeleteVertexArrays(1, &vao);
	}
	
	void load(){
		glBindVertexArray(vao);
		glBindBuffer(GL_ARRAY_BUFFER, vbo );
		glBufferData(GL_ARRAY_BUFFER, meshData.length, meshData.ptr, GL_STATIC_DRAW);
		glEnableVertexAttribArray(0);
		glEnableVertexAttribArray(1);
		glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6*float.sizeof, null);
		glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6*float.sizeof, cast(void*)(3*float.sizeof));
		glBindBuffer(GL_ARRAY_BUFFER,0);
		glBindVertexArray(0);
	}
	
	void bind(){
		glBindVertexArray(vao);
	}
		
	void render(){
		glDrawArrays(GL_TRIANGLES, 0, meshData.length/24);//meshData.length/12);
	}
	
}

