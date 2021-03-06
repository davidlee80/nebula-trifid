//------------------------------------------------------------------------------
//  billboardnode.cc
//  (C) 2013-2015 Individual contributors, see AUTHORS file
//------------------------------------------------------------------------------
#include "stdneb.h"
#include "billboardnode.h"
#include "billboardnodeinstance.h"

namespace Billboards
{
__ImplementClass(Billboards::BillboardNode, 'BBNO', Models::StateNode);

//------------------------------------------------------------------------------
/**
*/
BillboardNode::BillboardNode()
{
	// empty
}

//------------------------------------------------------------------------------
/**
*/
BillboardNode::~BillboardNode()
{
	// empty
}

//------------------------------------------------------------------------------
/**
*/
Ptr<Models::ModelNodeInstance> 
BillboardNode::CreateNodeInstance() const
{
	Ptr<Models::ModelNodeInstance> newInst = (Models::ModelNodeInstance*) BillboardNodeInstance::Create();
	return newInst;
}

} // namespace Models