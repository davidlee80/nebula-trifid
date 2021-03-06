#pragma once
//------------------------------------------------------------------------------
/**
    @class Tools::IDLAttributeLib
    
    Wraps a IDL attribute library definition.

    (C) 2012 Johannes Hirche, LTU Skelleftea
*/
#include "core/refcounted.h"
#include "util/string.h"
#include "io/xmlreader.h"
#include "toolkitutil/idldocument/idldependency.h"
#include "toolkitutil/idldocument/idlattribute.h"

//------------------------------------------------------------------------------
namespace Tools
{
class IDLAttributeLib : public Core::RefCounted
{
    __DeclareClass(IDLAttributeLib);
public:
    /// constructor
    IDLAttributeLib();
    /// parse the object from an XmlReader
    bool Parse(IO::XmlReader* reader);
    /// get error string
    const Util::String& GetError() const;       
	/// get dependencies
	const Util::Array<Ptr<IDLDependency>>& GetDependencies() const;
    /// get attributes
    const Util::Array<Ptr<IDLAttribute>>& GetAttributes() const;

private:
    /// set error string
    void SetError(const Util::String& e);

    Util::String error;
    Util::String name;    
    Util::Array<Ptr<IDLAttribute>> attributes;
	Util::Array<Ptr<IDLDependency>> dependencies;
};

//------------------------------------------------------------------------------
/**
*/
inline void
IDLAttributeLib::SetError(const Util::String& e)
{
	this->error = e;
}

//------------------------------------------------------------------------------
/**
*/
inline const Util::String&
IDLAttributeLib::GetError() const
{
	return this->error;
}

//------------------------------------------------------------------------------
/**
*/
/// get dependencies
inline const Util::Array<Ptr<IDLDependency>>& 
IDLAttributeLib::GetDependencies() const 
{
	return this->dependencies;
}

//------------------------------------------------------------------------------
/**
*/
inline const Util::Array<Ptr<IDLAttribute>>&
IDLAttributeLib::GetAttributes() const
{
	return this->attributes;
}

}