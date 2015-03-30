#pragma once
//------------------------------------------------------------------------------
/**
@class Physics::PhysicsStreamModelLoader
    
    Setup a physics model object from a stream. 
                
    
    (C) 2012 Johannes Hirche
*/
//------------------------------------------------------------------------------
#include "resources/streamresourceloader.h"
#include "coregraphics/base/resourcebase.h"
#include "physics/model/physicsmodel.h"

namespace Physics
{
class PhysicsStreamModelLoader : public Resources::StreamResourceLoader
{
    __DeclareClass(PhysicsStreamModelLoader);
public:
    /// constructor
    PhysicsStreamModelLoader();    

	virtual bool SetupResourceFromStream(const Ptr<IO::Stream>& stream);
private:
   
	void ParseData(const Ptr<Physics::PhysicsModel>& model, const Util::String & name, const Ptr<IO::BinaryReader>& stream);
	void ParseCollider(const Ptr<Physics::PhysicsModel>& model, const Util::String& name, const Ptr<IO::BinaryReader> & reader);	
	void ParsePhysicsObject(const Ptr<Physics::PhysicsModel>& model, const Ptr<IO::BinaryReader> & reader);
	void ParseJoint(const Ptr<Physics::PhysicsModel>& model, const Ptr<IO::BinaryReader> & reader);

   
protected:

};

} // namespace Physics
//------------------------------------------------------------------------------