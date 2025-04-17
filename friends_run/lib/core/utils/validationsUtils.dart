class ValidationUtils {
    static String? validateName(String? value) {
        if (value == null || value.isEmpty) {
            return "Digite seu nome completo";
        }

        if (!value.contains(" ")) {
            return "Digite seu nome completo";
        }

        final nameRegex = RegExp(r"^[A-Za-zÀ-ÖØ-öø-ÿ\s]+$");

        if (!nameRegex.hasMatch(value)) {
            return "O nome deve conter apenas letras e espaços";
        }

        return null;
    }

    static String? validateEmail(String? value) {
        if (value == null || value.isEmpty) return "Digite um email";
        final emailRegex =
        RegExp(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$');
        return emailRegex.hasMatch(value) ? null : "Email inválido";
    }

    static String? validatePassword(String? value) {
        if (value == null || value.isEmpty) return "Digite uma senha";
        if (value.length < 6) return "A senha deve ter pelo menos 6 caracteres";
        return null;
    }

    static String? validateConfirmPassword(String? value, String password) {
        if (value == null || value.isEmpty) return "Confirme sua senha";
        if (value != password) return "As senhas não coincidem";
        return null;
    }

    static String? validateAddress(String? value) {
        if (value == null || value.trim().isEmpty) {
            return "Digite um endereço ou local";
        }
        // Verifica um tamanho mínimo para evitar entradas muito curtas
        if (value.trim().length < 5) {
            return "Endereço muito curto";
        }
        // Opcional: Verifica se contém pelo menos uma letra (evita só números/símbolos)
        final letterRegex = RegExp(r'[a-zA-Z]');
        if (!letterRegex.hasMatch(value)) {
             return "Endereço parece inválido (use letras)";
        }
        // Validações mais complexas (como presença de cidade) são difíceis com Regex.
        // A validação real ocorrerá na geocodificação.
        return null;
    }
}

