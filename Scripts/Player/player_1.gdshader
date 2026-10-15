shader_type canvas_item;

uniform bool ativo = false;
// Amarelo bem clarinho, quase branco (para cabeça/luvas)
uniform vec4 ouro_suave : source_color = vec4(1.0, 0.98, 0.85, 1.0);
// Amarelo OURO vibrante e forte (para o short/canudo)
uniform vec4 ouro_vibrante : source_color = vec4(1.0, 0.9, 0.0, 1.0);

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    
    if (ativo && tex.a > 0.0) {
        // Pega a luminosidade original
        float luma = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
        
        // 1. O PRETO FICA TRANSPARENTE
        // Se for muito escuro (contorno/torso), apaga o pixel
        if (luma < 0.1) {
            discard;
        } else {
            // 2. O BRANCO FICA SÓ UM POUCO AMARELADO
            // O mix faz a transição: se for claro (branco), usa o ouro_suave
            // Se for médio (vermelho), usa o ouro_vibrante
            vec3 cor_final = mix(ouro_vibrante.rgb, ouro_suave.rgb, luma);
            
            // Dá um leve tapa no brilho final
            COLOR = vec4(cor_final, tex.a);
        }
    } else {
        COLOR = tex;
    }
}