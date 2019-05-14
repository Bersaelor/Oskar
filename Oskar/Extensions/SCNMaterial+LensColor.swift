//
//  SCNMaterial+LensColor.swift
//  LooC AR
//
//  Created by Konrad Feiler on 29.12.18.
//  Copyright © 2018 Konrad Feiler. All rights reserved.
//

import SceneKit

extension SCNMaterial {
    
    func set(lensColor: LensColor, lightIntensity: CGFloat) {
        diffuse.contents = lensColor.diffuse
        roughness.contents = lensColor.roughness
        metalness.contents = lensColor.metalness

        // lighting
        switch lensColor {
        case .photoChromic:
            transparency = 0.05 + 0.6 * lightIntensity * lightIntensity
        default:
            transparency = CGFloat(lensColor.transparency)
            transparent.contents = CGFloat(lensColor.transparency)
        }
        
        switch lensColor {
        case .clear, .antireflective, .shaded:
            transparencyMode = .dualLayer
            isDoubleSided = true
            setReflectiveClearShader(reflection: lensColor.reflectivity,
                                     minAlpha: lensColor == .shaded ? 0.65 : 0.0)
        default:
            transparencyMode = .default
            isDoubleSided = false
            removeShaderModifiers()
        }
    }
    
    private func setReflectiveClearShader(reflection: Float = 0.1, minAlpha: Float = 0.0) {
        let shaderModifier =
        """
#pragma transparent
#pragma body

vec3 light = _lightingContribution.specular;
float alpha = max(\(minAlpha), \(reflection) * min(1.0, 0.33 * light.r + 0.33 * light.g + 0.33 * light.b));
_output.color.rgb *= min(1.0, (1.5 + 2 * \(minAlpha)) * alpha);
_output.color.a = (0.75 + 0.25 * \(minAlpha)) * alpha;
"""
        self.shaderModifiers = [.fragment: shaderModifier]
    }
    
    func setToonShader() {
        self.shaderModifiers = [.fragment: shader(named: "ToonFragmentOutline"),
                                .lightingModel: shader(named: "ToonLightning"),
                                .surface: shader(named: "ToonSurface")]
    }
    
    private func removeShaderModifiers() {
        self.shaderModifiers = [SCNShaderModifierEntryPoint: String]()
    }
    
    func setCelShader() {
        removeShaderModifiers()

        let program = SCNProgram()
        program.delegate = self
        program.vertexFunctionName = "cel_shading_vertex"
        program.fragmentFunctionName = "cel_shading_fragment"
        
        self.program = program
    }
}

extension SCNMaterial: SCNProgramDelegate {
    
    public func program(_ program: SCNProgram, handleError error: Error) {
        log.error("SCNProgram failed to due to \(error)")
    }
}

private func shader(named fileName: String) -> String {
    guard let filepath = Bundle.main.path(forResource: fileName, ofType: "glsl") else { fatalError("Failed to find \(fileName)") }
    guard let shader = try? String(contentsOfFile: filepath) else { fatalError("Failed to parse \(filepath)") }
    return shader
}
