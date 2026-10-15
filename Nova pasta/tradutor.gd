extends Node
# Tradutor — aplica o Traduction.csv em TODA a interface do jogo.
#
# Por que ele existe: no Godot 4.7 o Label/Button NÃO troca sozinho o .text
# quando o idioma muda (testado em headless: nem na troca de locale, nem na
# hora de setar o texto — só o .tr() manual funciona). Então a gente guarda a
# frase de origem num meta e reescreve o texto na mão.
#
#   Tradutor.aplicar(self)           percorre a árvore e traduz tudo
#   Tradutor.definir(no, "Pular")    texto dinâmico: guarda a origem e traduz
#   Tradutor.trocar("en")            troca de idioma e reaplica em tudo
#   Tradutor.alternar()              pt <-> en (usado pela linha LANGUAGE)
#
# Regra de adoção (por isso não precisa listar as chaves): se o texto do nó
# continua igual ao que a gente escreveu (M_SAIDA) ou ao que é a origem
# (M_ORIGEM), ele não foi mexido por fora → retraduz da origem. Se mudou, é
# uma label dinâmica (HP, binding, nome do jogador) → adota o valor novo
# no lugar de sobrescrever.

const M_ORIGEM := "_i18n_origem"
const M_SAIDA := "_i18n_saida"

const IDIOMAS := {"pt": "Português", "en": "English"}
const PADRAO := "pt"

var idioma: String = PADRAO
var _cena_aplicada: Node = null

func _ready() -> void:
	# Precisa responder mesmo com a árvore pausada (é lá dentro do menu)
	process_mode = Node.PROCESS_MODE_ALWAYS
	idioma = _idioma_salvo()
	TranslationServer.set_locale(idioma)

func _process(_delta: float) -> void:
	var cena = get_tree().current_scene
	if cena != null and cena != _cena_aplicada:
		_cena_aplicada = cena
		aplicar(get_tree().root)

# ── Consultas ────────────────────────────────────────────────────────────────
func nome_idioma(cod: String) -> String:
	return str(IDIOMAS.get(cod, cod))

func tem_idioma(cod: String) -> bool:
	return IDIOMAS.has(cod)

# ── Troca de idioma ──────────────────────────────────────────────────────────
func trocar(cod: String) -> bool:
	if not IDIOMAS.has(cod) or cod == idioma:
		return false
	idioma = cod
	TranslationServer.set_locale(cod)
	_salvar_idioma(cod)
	aplicar(get_tree().root)
	return true

# Alterna entre os dois idiomas e devolve o que ficou valendo
func alternar() -> String:
	trocar("en" if idioma == "pt" else "pt")
	return idioma

# ── Aplicação ────────────────────────────────────────────────────────────────
func aplicar(no: Node) -> void:
	if no == null or not is_instance_valid(no):
		return
	_traduz(no)
	for filho in no.get_children():
		aplicar(filho)

# Texto que o código vai escrever agora (guarda a origem pra troca de idioma)
func definir(no: Node, bruto: String) -> void:
	if no == null or not is_instance_valid(no) or not (no is Control):
		return
	(no as Control).auto_translate = false
	var prop := _propriedade(no)
	if prop == "":
		return
	no.set_meta(M_ORIGEM, bruto)
	var novo := tr(bruto)
	no.set(prop, novo)
	no.set_meta(M_SAIDA, novo)

func _propriedade(no: Node) -> String:
	# LineEdit/Edit: o "text" é digitado pelo jogador, só o placeholder é UI
	if no is LineEdit or no is TextEdit:
		return "placeholder_text"
	if no is OptionButton:
		return "" # itens = nome de dispositivo/perfil do usuário
	if "text" in no:
		return "text"
	return ""

func _traduz(no: Node) -> void:
	if not (no is Control):
		return
	var c := no as Control
	# Desliga a auto-tradução nativa: senão corre risco de traduzir DUAS vezes
	# (o Godot desenha com .tr() por baixo e a gente já gravou o texto certo).
	c.auto_translate = false
	var prop := _propriedade(no)
	if prop == "":
		return
	_traduz_prop(no, prop)

func _traduz_prop(no: Node, prop: String) -> void:
	var atual := str(no.get(prop))
	if atual == "" and not no.has_meta(M_ORIGEM):
		return
	if no.has_meta(M_ORIGEM):
		var origem := str(no.get_meta(M_ORIGEM))
		var saida := str(no.get_meta(M_SAIDA, origem))
		if atual == saida or atual == origem:
			# Ninguém mexeu: retraduz da frase original
			atual = tr(origem)
		else:
			# Texto trocado por fora (label dinâmica): adota o valor novo
			no.set_meta(M_ORIGEM, atual)
			atual = tr(atual)
	else:
		# Primeira vez que a gente vê esse nó
		no.set_meta(M_ORIGEM, atual)
		atual = tr(atual)
	no.set(prop, atual)
	no.set_meta(M_SAIDA, atual)

# ── Persistência (fica no Keys.json, junto com o resto) ──────────────────────
func _idioma_salvo() -> String:
	var dados: Dictionary = gvar._ler_json(gvar.get_save_path())
	var v := str(dados.get("idioma", ""))
	if IDIOMAS.has(v):
		return v
	# Sem escolha guardada: respeita o idioma do sistema
	var loc := TranslationServer.get_locale().to_lower()
	return "en" if loc.begins_with("en") else PADRAO

func _salvar_idioma(cod: String) -> void:
	var path: String = gvar.get_save_path()
	var dados: Dictionary = gvar._ler_json(path)
	dados["idioma"] = cod
	gvar._gravar_json(path, dados)
