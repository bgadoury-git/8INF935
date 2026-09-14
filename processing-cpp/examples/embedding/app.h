// app.h -- the "drop into an existing project" pattern: keep the PApplet
// subclass and the Processing.h include confined to app.cpp. The rest of
// your codebase only ever needs to see this plain function declaration.
#pragma once

void run_particle_view();
