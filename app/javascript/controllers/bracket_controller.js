import { Controller } from "@hotwired/stimulus"

// Handles the interactive play-in bracket:
// - Saves picks via AJAX
// - Auto-populates the final game card when round-1 picks are made
export default class extends Controller {
  static values = {
    picksUrl: String,
    picks: Object,   // { game_id: picked_winner_id, ... }
    eastLockTime: String,  // ISO8601 UTC
    westLockTime: String,
  }

  connect() {
    this.picksMap = this.picksValue || {}
    this.renderLockLabels()
    this.applyLockState()
  }

  lockTimeFor(conference) {
    const iso = conference === "East" ? this.eastLockTimeValue : this.westLockTimeValue
    return iso ? new Date(iso) : null
  }

  isLocked(conference) {
    const t = this.lockTimeFor(conference)
    return t && Date.now() >= t.getTime()
  }

  renderLockLabels() {
    this.element.querySelectorAll("[data-bracket-lock-label-conference]").forEach(el => {
      const conference = el.dataset.bracketLockLabelConference
      const lockTime   = this.lockTimeFor(conference)
      if (!lockTime) return

      if (this.isLocked(conference)) {
        el.textContent = "Picks locked"
        el.classList.remove("text-gray-500")
        el.classList.add("text-red-400")
      } else {
        const formatted = lockTime.toLocaleString(undefined, {
          weekday: "long",
          hour:    "numeric",
          minute:  "2-digit",
          timeZoneName: "short",
        })
        el.textContent = `Picks lock ${formatted}`
      }
    })
  }

  applyLockState() {
    for (const conference of ["East", "West"]) {
      if (!this.isLocked(conference)) continue
      const conferenceEl = this.element.querySelector(`[data-conference="${conference}"]`)
      if (!conferenceEl) continue
      conferenceEl.querySelectorAll(".team-pick-btn").forEach(btn => {
        btn.disabled = true
        btn.classList.add("cursor-not-allowed", "opacity-60")
        btn.classList.remove("hover:bg-gray-700")
      })
    }
  }

  async pickWinner(event) {
    const btn = event.currentTarget
    const gameId      = parseInt(btn.dataset.bracketGameIdParam)
    const winnerId    = parseInt(btn.dataset.bracketWinnerIdParam)
    const conference  = btn.dataset.bracketConferenceParam
    const gameType    = btn.dataset.bracketGameTypeParam

    if (this.isLocked(conference)) return

    const isDeselect = this.picksMap[String(gameId)] === winnerId

    if (isDeselect) {
      delete this.picksMap[String(gameId)]
      this.clearGameCardUI(gameId)
    } else {
      this.picksMap[String(gameId)] = winnerId
      this.updateGameCardUI(gameId, winnerId)
    }

    // If this is a round-1 game, refresh the final card
    if (gameType === "seven_eight" || gameType === "nine_ten") {
      this.refreshFinalCard(conference)
    }

    // Persist to server (null clears the pick)
    await this.savePick(gameId, isDeselect ? null : winnerId)
  }

  clearGameCardUI(gameId) {
    const card = this.element.querySelector(`[data-bracket-game-id="${gameId}"]`)
    if (!card) return

    card.querySelectorAll(".team-pick-btn").forEach(btn => {
      btn.style.backgroundColor = ""
      btn.style.color = ""
      btn.classList.add("bg-gray-800", "hover:bg-gray-700", "text-gray-200")
    })
  }

  updateGameCardUI(gameId, winnerId) {
    const card = this.element.querySelector(`[data-bracket-game-id="${gameId}"]`)
    if (!card) return

    card.querySelectorAll(".team-pick-btn").forEach(btn => {
      const thisWinnerId = parseInt(btn.dataset.bracketWinnerIdParam)
      const isSelected   = thisWinnerId === winnerId

      btn.classList.remove("bg-gray-800", "hover:bg-gray-700", "text-gray-200")

      if (isSelected) {
        btn.style.backgroundColor = btn.dataset.teamColor
        btn.style.color = btn.dataset.teamSecondaryColor
      } else {
        btn.style.backgroundColor = ""
        btn.style.color = ""
        btn.classList.add("bg-gray-800", "hover:bg-gray-700", "text-gray-200")
      }
    })
  }

  refreshFinalCard(conference) {
    const finalContainer = this.element.querySelector(`[data-conference="${conference}"] [data-bracket-target="finalCard"]`)
    if (!finalContainer) return

    const sevenEightGameId = parseInt(finalContainer.dataset.sevenEightGameId)
    const nineTenGameId    = parseInt(finalContainer.dataset.nineTenGameId)

    const sevenEightPick = this.picksMap[String(sevenEightGameId)]
    const nineTenPick    = this.picksMap[String(nineTenGameId)]

    // Determine team IDs for each slot from the existing game card buttons
    const sevenEightCard = this.element.querySelector(`[data-bracket-game-id="${sevenEightGameId}"]`)
    const nineTenCard    = this.element.querySelector(`[data-bracket-game-id="${nineTenGameId}"]`)

    const finalGameId = parseInt(finalContainer.dataset.bracketGameId)

    // Home slot = loser of 7v8 (opposite of 7v8 pick)
    let homeTeamId = null, homeTeamSeed = null, homeTeamName = null, homeTeamColor = null, homeTeamSecondaryColor = null
    if (sevenEightPick && sevenEightCard) {
      const btns = sevenEightCard.querySelectorAll(".team-pick-btn")
      btns.forEach(btn => {
        const id = parseInt(btn.dataset.bracketWinnerIdParam)
        if (id !== sevenEightPick) {
          homeTeamId             = id
          homeTeamSeed           = btn.querySelector("span:first-child")?.textContent?.replace("#", "")
          homeTeamName           = btn.querySelector("span:nth-child(2)")?.textContent
          homeTeamColor          = btn.dataset.teamColor
          homeTeamSecondaryColor = btn.dataset.teamSecondaryColor
        }
      })
    }

    // Away slot = winner of 9v10
    let awayTeamId = null, awayTeamSeed = null, awayTeamName = null, awayTeamColor = null, awayTeamSecondaryColor = null
    if (nineTenPick && nineTenCard) {
      const btns = nineTenCard.querySelectorAll(".team-pick-btn")
      btns.forEach(btn => {
        const id = parseInt(btn.dataset.bracketWinnerIdParam)
        if (id === nineTenPick) {
          awayTeamId             = id
          awayTeamSeed           = btn.querySelector("span:first-child")?.textContent?.replace("#", "")
          awayTeamName           = btn.querySelector("span:nth-child(2)")?.textContent
          awayTeamColor          = btn.dataset.teamColor
          awayTeamSecondaryColor = btn.dataset.teamSecondaryColor
        }
      })
    }

    // If the current final pick is for a team no longer in the final, clear it
    let currentFinalPick = this.picksMap[String(finalGameId)]
    if (currentFinalPick !== undefined) {
      const stillValid = currentFinalPick === homeTeamId || currentFinalPick === awayTeamId
      if (!stillValid) {
        delete this.picksMap[String(finalGameId)]
        currentFinalPick = undefined
        this.savePick(finalGameId, null)
      }
    }

    // Re-render the final card slots
    finalContainer.innerHTML = this.buildFinalCardHTML({
      finalGameId,
      conference,
      homeTeamId, homeTeamSeed, homeTeamName, homeTeamColor, homeTeamSecondaryColor,
      awayTeamId, awayTeamSeed, awayTeamName, awayTeamColor, awayTeamSecondaryColor,
      currentFinalPick,
      sevenEightGameId,
      nineTenGameId
    })

    if (this.isLocked(conference)) {
      finalContainer.querySelectorAll(".team-pick-btn").forEach(btn => {
        btn.disabled = true
        btn.classList.add("cursor-not-allowed", "opacity-60")
      })
    }

    // Re-attach event listeners by re-adding data-action (Stimulus handles via delegation already)
  }

  buildFinalCardHTML({ finalGameId, conference, homeTeamId, homeTeamSeed, homeTeamName, homeTeamColor, homeTeamSecondaryColor,
                       awayTeamId, awayTeamSeed, awayTeamName, awayTeamColor, awayTeamSecondaryColor, currentFinalPick,
                       sevenEightGameId, nineTenGameId }) {

    const makeTeamBtn = (teamId, teamSeed, teamName, teamColor, teamSecondaryColor, labelText, slotType) => {
      const isSelected  = currentFinalPick === teamId
      const colorClass  = isSelected ? "font-bold" : "bg-gray-800 hover:bg-gray-700 text-gray-200"
      const inlineStyle = isSelected
        ? `style="background-color: ${teamColor}; color: ${teamSecondaryColor};"`
        : ""

      return `
        <button type="button"
                class="team-pick-btn w-full flex items-center gap-3 px-4 py-3 transition-all duration-150 text-left ${colorClass}"
                ${inlineStyle}
                data-action="click->bracket#pickWinner"
                data-bracket-game-id-param="${finalGameId}"
                data-bracket-winner-id-param="${teamId}"
                data-bracket-conference-param="${conference}"
                data-bracket-game-type-param="final"
                data-bracket-home-away-param="${slotType}"
                data-team-color="${teamColor}"
                data-team-secondary-color="${teamSecondaryColor}">
          <span class="text-xs font-bold w-4">#${teamSeed}</span>
          <span class="font-semibold text-sm">${teamName}</span>
          <span class="text-xs ml-1 opacity-70">${labelText}</span>
        </button>`
    }

    const makePlaceholder = (label) => `
      <div class="w-full flex items-center gap-3 px-4 py-3 bg-gray-800 opacity-50">
        <span class="text-xs font-bold text-gray-500 w-4">?</span>
        <span class="text-sm text-gray-500 italic">${label}</span>
      </div>`

    const homeSlot = homeTeamId
      ? makeTeamBtn(homeTeamId, homeTeamSeed, homeTeamName, homeTeamColor, homeTeamSecondaryColor, "(loser of #7v8)", "home")
      : makePlaceholder("Loser of #7 vs #8")

    const awaySlot = awayTeamId
      ? makeTeamBtn(awayTeamId, awayTeamSeed, awayTeamName, awayTeamColor, awayTeamSecondaryColor, "(winner of #9v10)", "away")
      : makePlaceholder("Winner of #9 vs #10")

    const divider = `<div class="h-px bg-gray-700 mx-4"></div>`

    return homeSlot + divider + awaySlot
  }

  async savePick(gameId, winnerId) {
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    try {
      const response = await fetch(this.picksUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": token,
          "Accept": "application/json"
        },
        body: JSON.stringify({ game_id: gameId, picked_winner_id: winnerId })
      })
      if (!response.ok) {
        console.error("Failed to save pick", await response.json())
      }
    } catch (err) {
      console.error("Network error saving pick", err)
    }
  }
}
