//------------------------------------------------------------------------------
//  imguirtplugin.cc
//  (C) 2012-2015 Individual contributors, see AUTHORS file
//------------------------------------------------------------------------------
#include "stdneb.h"
#include "imguirtplugin.h"

namespace Dynui
{
__ImplementClass(Dynui::ImguiRTPlugin, 'IMRT', RenderModules::RTPlugin);

//------------------------------------------------------------------------------
/**
*/
ImguiRTPlugin::ImguiRTPlugin()
{
	// empty
}

//------------------------------------------------------------------------------
/**
*/
ImguiRTPlugin::~ImguiRTPlugin()
{
	// empty
}

//------------------------------------------------------------------------------
/**
*/
void
ImguiRTPlugin::OnRegister()
{
	this->renderer = ImguiRenderer::Create();
	this->renderer->Setup();
}

//------------------------------------------------------------------------------
/**
*/
void
ImguiRTPlugin::OnUnregister()
{
	this->renderer->Discard();
	this->renderer = 0;
}

//------------------------------------------------------------------------------
/**
*/
void
ImguiRTPlugin::OnRenderFrameBatch(const Ptr<Frame::FrameBatch>& frameBatch)
{
	n_assert(this->renderer.isvalid());
	if (CoreGraphics::BatchType::UI == frameBatch->GetType())
	{
		this->renderer->Render();
	}
}

//------------------------------------------------------------------------------
/**
*/
void
ImguiRTPlugin::OnWindowResized(SizeT width, SizeT height)
{
	n_assert(this->renderer.isvalid());
	this->renderer->SetRectSize(width, height);
}

} // namespace Imgui