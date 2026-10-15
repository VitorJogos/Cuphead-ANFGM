shader_type canvas_item;

uniform bool selecionado = false;
// Agora essa textura vai ler apenas o que capturamos antes do botão bege aparecer!
uniform sampler2D texto_fundo : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    if (selecionado && tex_color.a > 0.0) {
        // Pega a textura do fundo isolado
        vec4 cor_fundo = texture(texto_fundo, SCREEN_UV);
        COLOR = vec4(cor_fundo.rgb, tex_color.a);
    } else {
        COLOR = tex_color;
    }
}