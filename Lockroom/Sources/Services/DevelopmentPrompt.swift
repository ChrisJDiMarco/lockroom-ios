import Foundation

enum DevelopmentPrompt {
    static func makePrompt(recipe: DevelopmentRecipe) -> String {
        """
        Recreate the provided photo as the best possible version of the same image.

        Preserve the real subject, scene layout, object identities, facial identity if any person appears, perspective, and moment. Do not invent new objects, people, text, branding, landmarks, or fantasy elements. Treat this as a premium photographic development pass, not a redesign.

        Improve it as if it had been captured with a professional full-frame camera and exceptional lens:
        - \(recipe.lensRead)
        - \(recipe.toneRead)
        - more natural color balance, cleaner dynamic range, sharper-but-not-artificial detail
        - tasteful highlight rolloff, accurate skin and material tones, restrained noise reduction
        - remove minor phone-camera artifacts, over-sharpening, muddy shadows, lens smears, and awkward exposure shifts

        Output a polished, photorealistic image. \(recipe.outputIntent)
        """
    }
}

