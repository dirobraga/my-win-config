# =============================================================================
#   setup.ps1 - Diro's dotfiles-win
#   Repositório: https://github.com/dirobraga/dotfiles-win
# =============================================================================

param(
    [switch]$SkipWinUtil,
    [switch]$SkipSpotX,
    [switch]$SkipCursor,
    [switch]$SkipWallpaper,
    [switch]$SkipAfterburner,
    [switch]$SkipRivaTuner
)

# =============================================================================
# UTILITÁRIOS
# =============================================================================

function Write-Header {
    Clear-Host
    Write-Host ""
    Write-Host "  ██████╗  ██╗██████╗  ██████╗ " -ForegroundColor Magenta
    Write-Host "  ██╔══██╗ ██║██╔══██╗██╔═══██╗" -ForegroundColor Magenta
    Write-Host "  ██║  ██║ ██║██████╔╝██║   ██║" -ForegroundColor Magenta
    Write-Host "  ██║  ██║ ██║██╔══██╗██║   ██║" -ForegroundColor Magenta
    Write-Host "  ██████╔╝ ██║██║  ██║╚██████╔╝" -ForegroundColor Magenta
    Write-Host "  ╚═════╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ " -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  dotfiles-win Setup" -ForegroundColor White
    Write-Host "  github.com/dirobraga/dotfiles-win" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""
}

function Write-Step([string]$msg) {
    Write-Host ""
    Write-Host "  ▶ $msg" -ForegroundColor Cyan
}

function Write-Ok([string]$msg) {
    Write-Host "    ✓ $msg" -ForegroundColor Green
}

function Write-Warn([string]$msg) {
    Write-Host "    ! $msg" -ForegroundColor Yellow
}

function Write-Fail([string]$msg) {
    Write-Host "    ✗ $msg" -ForegroundColor Red
}

function Write-Skip([string]$msg) {
    Write-Host "    ~ $msg (pulado via flag)" -ForegroundColor DarkGray
}

function Confirm-Step([string]$question) {
    $answer = Read-Host "    $question [S/N]"
    return ($answer -match '^[Ss]')
}

function Require-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent() `
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Host ""
        Write-Fail "Este script precisa ser rodado como Administrador."
        Write-Host "    Clique com botão direito no PowerShell > 'Executar como administrador'" -ForegroundColor DarkGray
        Write-Host ""
        exit 1
    }
}

# =============================================================================
# PASSO 1 - WINUTIL (debloat + apps + tweaks)
# =============================================================================

function Install-WinUtil {
    if ($SkipWinUtil) { Write-Skip "WinUtil"; return }

    Write-Step "Chris Titus WinUtil — debloat, apps e tweaks"

    $configPath = "$PSScriptRoot\debloat-config.json"

    if (-not (Test-Path $configPath)) {
        Write-Fail "debloat-config.json não encontrado em: $configPath"
        Write-Warn "Pulando etapa do WinUtil..."
        return
    }

    Write-Warn "O WinUtil vai abrir em uma nova janela."
    Write-Warn "Passos manuais necessários:"
    Write-Host "      1. Clique na engrenagem > Import" -ForegroundColor DarkGray
    Write-Host "      2. Selecione o arquivo: debloat-config.json" -ForegroundColor DarkGray
    Write-Host "      3. Aba 'Install' > clique 'Install/Upgrade Applications'" -ForegroundColor DarkGray
    Write-Host "      4. Aba 'Tweaks'  > clique 'Run Tweaks'" -ForegroundColor DarkGray
    Write-Host ""

    if (Confirm-Step "Abrir o WinUtil agora?") {
        try {
            irm "https://christitus.com/win" | iex
            Read-Host "`n    Pressione ENTER quando terminar o WinUtil"
            Write-Ok "WinUtil concluído."
        }
        catch {
            Write-Fail "Erro ao carregar o WinUtil: $_"
        }
    } else {
        Write-Warn "WinUtil pulado pelo usuário."
    }
}

# =============================================================================
# PASSO 2 - SPOTX (Spotify sem anúncios)
# =============================================================================

function Install-SpotX {
    if ($SkipSpotX) { Write-Skip "SpotX"; return }

    Write-Step "SpotX — Spotify sem anúncios"

    $spotifyPath = "$env:APPDATA\Spotify\Spotify.exe"

    if (-not (Test-Path $spotifyPath)) {
        Write-Warn "Spotify não encontrado em: $spotifyPath"
        Write-Warn "Instale o Spotify antes de rodar o SpotX."

        if (-not (Confirm-Step "Tentar instalar SpotX mesmo assim?")) {
            Write-Warn "SpotX pulado."
            return
        }
    }

    Write-Warn "Nota: O SpotX pode parar de funcionar após atualizações do Spotify."

    try {
        iex "& { $(iwr -useb 'https://raw.githubusercontent.com/SpotX-Official/SpotX/refs/heads/main/run.ps1') } -new_theme"
        Write-Ok "SpotX instalado com sucesso."
    }
    catch {
        Write-Fail "Erro ao instalar SpotX: $_"
    }
}

# =============================================================================
# PASSO 3 - CURSOR DO MOUSE
# =============================================================================

function Install-Cursor {
    if ($SkipCursor) { Write-Skip "Cursor do mouse"; return }

    Write-Step "Cursor do mouse customizado"

    $infPath = "$PSScriptRoot\cursor\Install.inf"

    if (-not (Test-Path $infPath)) {
        Write-Fail "Arquivo não encontrado: $infPath"
        return
    }

    try {
        Start-Process -FilePath "rundll32.exe" `
            -ArgumentList "setupapi,InstallHinfSection DefaultInstall 132 `"$infPath`"" `
            -Wait -NoNewWindow

        Write-Ok "Cursor instalado."
        Write-Warn "Ative manualmente: Painel de Controle > Mouse > Ponteiros > selecione o esquema instalado."
    }
    catch {
        Write-Fail "Erro ao instalar cursor: $_"
    }
}

# =============================================================================
# PASSO 4 - WALLPAPER
# =============================================================================

function Set-Wallpaper {
    if ($SkipWallpaper) { Write-Skip "Wallpaper"; return }

    Write-Step "Wallpaper"

    $wallpaperDir = "$PSScriptRoot\wallpaper"

    if (-not (Test-Path $wallpaperDir)) {
        Write-Fail "Pasta não encontrada: $wallpaperDir"
        return
    }

    # Pega a primeira imagem encontrada na pasta
    $wallpaperFile = Get-ChildItem -Path $wallpaperDir `
        -Include *.jpg, *.jpeg, *.png `
        -Recurse | Select-Object -First 1

    if (-not $wallpaperFile) {
        Write-Fail "Nenhuma imagem encontrada na pasta wallpaper."
        return
    }

    try {
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
        [Wallpaper]::SystemParametersInfo(0x0014, 0, $wallpaperFile.FullName, 0x0003) | Out-Null
        Write-Ok "Wallpaper definido: $($wallpaperFile.Name)"
    }
    catch {
        Write-Fail "Erro ao definir wallpaper: $_"
    }
}

# =============================================================================
# PASSO 5 - PERFIS DO MSI AFTERBURNER
# =============================================================================

function Copy-AfterburnerProfiles {
    if ($SkipAfterburner) { Write-Skip "MSI Afterburner"; return }

    Write-Step "Perfis do MSI Afterburner"

    $src  = "$PSScriptRoot\backups\afterburner"
    $dest = "C:\Program Files (x86)\MSI Afterburner\Profiles"

    if (-not (Test-Path $src)) {
        Write-Fail "Pasta de backup não encontrada: $src"
        return
    }

    if (-not (Test-Path $dest)) {
        Write-Fail "MSI Afterburner não está instalado (pasta não encontrada: $dest)"
        Write-Warn "Instale o MSI Afterburner pelo WinUtil e rode o script novamente com -SkipWinUtil."
        return
    }

    try {
        Copy-Item "$src\*" $dest -Force -Recurse
        Write-Ok "Perfis do Afterburner copiados para: $dest"
    }
    catch {
        Write-Fail "Erro ao copiar perfis do Afterburner: $_"
    }
}

# =============================================================================
# PASSO 6 - PERFIS DO RIVATUNER
# =============================================================================

function Copy-RivaTunerProfiles {
    if ($SkipRivaTuner) { Write-Skip "RivaTuner"; return }

    Write-Step "Perfis do RivaTuner Statistics Server"

    $src  = "$PSScriptRoot\backups\rivaturner"
    $dest = "C:\Program Files (x86)\RivaTuner Statistics Server\Profiles"

    if (-not (Test-Path $src)) {
        Write-Fail "Pasta de backup não encontrada: $src"
        return
    }

    if (-not (Test-Path $dest)) {
        Write-Fail "RivaTuner não está instalado (pasta não encontrada: $dest)"
        Write-Warn "Instale o RivaTuner pelo WinUtil e rode o script novamente com -SkipWinUtil."
        return
    }

    try {
        Copy-Item "$src\*" $dest -Force -Recurse
        Write-Ok "Perfis do RivaTuner copiados para: $dest"
        Write-Host "      Atalhos do overlay:" -ForegroundColor DarkGray
        Write-Host "        END      → ativar/desativar overlay" -ForegroundColor DarkGray
        Write-Host "        PgUp/Dn  → alternar perfil" -ForegroundColor DarkGray
        Write-Host "        CTRL+END → travar a 60 FPS" -ForegroundColor DarkGray
    }
    catch {
        Write-Fail "Erro ao copiar perfis do RivaTuner: $_"
    }
}

# =============================================================================
# MAIN
# =============================================================================

Require-Admin
Write-Header

Write-Host "  Flags ativas:" -ForegroundColor DarkGray
if ($SkipWinUtil)     { Write-Host "    -SkipWinUtil"     -ForegroundColor DarkGray }
if ($SkipSpotX)       { Write-Host "    -SkipSpotX"       -ForegroundColor DarkGray }
if ($SkipCursor)      { Write-Host "    -SkipCursor"      -ForegroundColor DarkGray }
if ($SkipWallpaper)   { Write-Host "    -SkipWallpaper"   -ForegroundColor DarkGray }
if ($SkipAfterburner) { Write-Host "    -SkipAfterburner" -ForegroundColor DarkGray }
if ($SkipRivaTuner)   { Write-Host "    -SkipRivaTuner"   -ForegroundColor DarkGray }

Install-WinUtil
Install-SpotX
Install-Cursor
Set-Wallpaper
Copy-AfterburnerProfiles
Copy-RivaTunerProfiles

Write-Host ""
Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  ✓ Setup concluído!" -ForegroundColor Green
Write-Host ""
Write-Host "  Recomendado: reinicie o PC para aplicar todas as mudanças." -ForegroundColor Yellow
Write-Host ""

if (Confirm-Step "Reiniciar agora?") {
    Restart-Computer -Force
}
