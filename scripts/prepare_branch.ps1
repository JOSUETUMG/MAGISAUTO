<#
PowerShell helper: prepara una rama, añade y commitea cambios y sube al remoto.
Uso: Ejecutar desde la raíz del repositorio:
  PowerShell -ExecutionPolicy Bypass -File .\scripts\prepare_branch.ps1

El script intenta crear la rama, commitear todos los cambios y hacer push.
Si tienes 'gh' instalado y quieres crear el PR, responde 'Y' cuando se pregunte.
#>

function ExitWithMessage($msg) {
	Write-Host $msg -ForegroundColor Yellow
	exit 1
}

# Comprobar git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
	ExitWithMessage "git no está disponible en este entorno. Instala Git y vuelve a ejecutar el script."
}

$defaultBranch = "feature/magis-automotiz"
$branch = Read-Host "Nombre de la rama [ENTER para usar '$defaultBranch']"
if ([string]::IsNullOrWhiteSpace($branch)) { $branch = $defaultBranch }

Write-Host "Creando rama: $branch" -ForegroundColor Cyan

# Crear la rama (si existe, cambiar a ella)
try {
	git rev-parse --verify $branch > $null 2>&1
	if ($LASTEXITCODE -eq 0) {
		git checkout $branch
	} else {
		git checkout -b $branch
	}
} catch {
	ExitWithMessage "Error al crear/usar la rama: $_"
}

Write-Host "Añadiendo todos los cambios..." -ForegroundColor Cyan
git add .

$defaultMsg = "feat: agregar sitio MAGIS AUTOMOTIZ (UI estática) y referencias personales"
$msg = Read-Host "Mensaje de commit [ENTER para usar mensaje por defecto]"
if ([string]::IsNullOrWhiteSpace($msg)) { $msg = $defaultMsg }

git commit -m "$msg" 2>$null
if ($LASTEXITCODE -ne 0) {
	Write-Host "No se realizaron cambios para commitear (o commit fallido). Continuando..." -ForegroundColor Yellow
}

Write-Host "Haciendo push de la rama a origin/$branch..." -ForegroundColor Cyan
git push -u origin $branch
if ($LASTEXITCODE -ne 0) {
	ExitWithMessage "git push falló. Comprueba credenciales, conexión y que el remoto 'origin' esté configurado."
}

# Crear PR opcional con gh
if (Get-Command gh -ErrorAction SilentlyContinue) {
	$createPR = Read-Host "¿Quieres crear un Pull Request usando 'gh' ahora? (Y/N)"
	if ($createPR -match '^[Yy]') {
		$title = Read-Host "Título del PR [ENTER para usar por defecto]"
		if ([string]::IsNullOrWhiteSpace($title)) { $title = $defaultMsg }
		$bodyFile = "PR_BODY.md"
		if (-not (Test-Path $bodyFile)) {
			Write-Host "No se encuentra PR_BODY.md en la raíz. Crear PR sin cuerpo." -ForegroundColor Yellow
			gh pr create --base main --head $branch --title "$title"
		} else {
			gh pr create --base main --head $branch --title "$title" --body-file "$bodyFile"
		}
		if ($LASTEXITCODE -ne 0) { Write-Host "gh pr create falló o fue cancelado." -ForegroundColor Yellow }
	}
} else {
	Write-Host "gh CLI no está instalado. Para crear el PR usa la interfaz web o instala gh y ejecuta: gh pr create ..." -ForegroundColor Yellow
}

Write-Host "Proceso completado. Revisa el repositorio y el PR (si lo creaste)." -ForegroundColor Green
