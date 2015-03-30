//------------------------------------------------------------------------------
//  column.cc
//  (C) 2006 Radon Labs GmbH
//  (C) 2013-2015 Individual contributors, see AUTHORS file
//------------------------------------------------------------------------------
#include "stdneb.h"
#include "addons/db/column.h"

namespace Db
{
//------------------------------------------------------------------------------
/**
*/
Column::Column() :
    type(Default),
    committed(false)
{
    // empty
}

//------------------------------------------------------------------------------
/**
*/
Column::Column(const Attr::AttrId& id, Type t) :
    attrId(id),
    type(t),
    committed(false)
{
    // empty
}

} // namespace Db