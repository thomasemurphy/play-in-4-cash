import { Controller } from "@hotwired/stimulus"

// Handles the interactive play-in bracket:
// - Saves picks via AJAX
// - Auto-populates the final game card when round-1 picks are made
export default class extends Controller {
  static values = {
    picksUrl: String,
    picks: Object,   // { game_id: picked_winner_id, ... }
  }

  connect() {
    // picks is keyed by string (JSON keys are always strings)
    this.picksMap = this.picksValue || {}
  }

  async pickWinner(event) {
    const btn = event.currentTarget
    const gameId      = parseInt(btn.dataset.bracketGameIdParam)
    const winnerId    = parseInt(btn.dataset.bracketWinnerIdParam)
    const conference  = btn.dataset.bracketConferenceParam
    const gameType    = btn.dataset.bracketGameTypeParam

    // Optimistically update UI
    this.updateGameCardUI(gameId, winnerId)

    // Track pick locally
    this.picksMap[String(gameId)] = winnerId

    // If this is a round-1 game, refresh the final card
    if (gameType === "seven_eight" || gameType === "nine_ten") {
      this.refreshFinalCard(conference)
    }

    // Persist to server
    await this.savePick(gameId, winnerId)
  }

  updateGameCardUI(gameId, winnerId) {
    const card = this.element.querySelector(`[data-bracket-game-id="${gameId}"]`)
    if (!card) return

    card.querySelectorAll(".team-pick-btn").forEach(btn => {
      const thisWinnerId = parseInt(btn.dataset.bracketWinnerIdParam)
      const isSelected   = thisWinnerId === winnerId

      // Reset classes
      btn.classList.remove("bg-orange-500", "text-white", "font-bold", "bg-gray-800", "hover:bg-gray-700", "text-gray-200")

      if (isSelected) {
        btn.classList.add("bg-orange-500", "text-white", "font-bold")
        // Ensure checkmark badge exists
        if (!btn.querySelector(".pick-check")) {
          const badge = document.createElement("span")
          badge.className = "ml-auto text-xs font-black pick-check"
          badge.textContent = "✓ PICK"
          btn.appendChild(badge)
        }
      } else {
        btn.classList.add("bg-gray-800", "hover:bg-gray-700", "text-gray-200")
        btn.querySelector(".pick-check")?.remove()
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
    let homeTeamId = null, homeTeamSeed = null, homeTeamName = null
    if (sevenEightPick && sevenEightCard) {
      const btns = sevenEightCard.querySelectorAll(".team-pick-btn")
      btns.forEach(btn => {
        const id = parseInt(btn.dataset.bracketWinnerIdParam)
        if (id !== sevenEightPick) {
          homeTeamId   = id
          homeTeamSeed = btn.querySelector("span:first-child")?.textContent?.replace("#", "")
          homeTeamName = btn.querySelector("span:nth-child(2)")?.textContent
        }
      })
    }

    // Away slot = winner of 9v10
    let awayTeamId = null, awayTeamSeed = null, awayTeamName = null
    if (nineTenPick && nineTenCard) {
      const btns = nineTenCard.querySelectorAll(".team-pick-btn")
      btns.forEach(btn => {
        const id = parseInt(btn.dataset.bracketWinnerIdParam)
        if (id === nineTenPick) {
          awayTeamId   = id
          awayTeamSeed = btn.querySelector("span:first-child")?.textContent?.replace("#", "")
          awayTeamName = btn.querySelector("span:nth-child(2)")?.textContent
        }
      })
    }

    const currentFinalPick = this.picksMap[String(finalGameId)]

    // Re-render the final card slots
    finalContainer.innerHTML = this.buildFinalCardHTML({
      finalGameId,
      conference,
      homeTeamId, homeTeamSeed, homeTeamName,
      awayTeamId, awayTeamSeed, awayTeamName,
      currentFinalPick,
      sevenEightGameId,
      nineTenGameId
    })

    // Re-attach event listeners by re-adding data-action (Stimulus handles via delegation already)
  }

  buildFinalCardHTML({ finalGameId, conference, homeTeamId, homeTeamSeed, homeTeamName,
                       awayTeamId, awayTeamSeed, awayTeamName, currentFinalPick,
                       sevenEightGameId, nineTenGameId }) {

    const makeTeamBtn = (teamId, teamSeed, teamName, labelText, slotType) => {
      const isSelected = currentFinalPick === teamId
      const colorClass = isSelected
        ? "bg-orange-500 text-white font-bold"
        : "bg-gray-800 hover:bg-gray-700 text-gray-200"
      const checkmark  = isSelected ? `<span class="ml-auto text-xs font-black pick-check">✓ PICK</span>` : ""

      return `
        <button type="button"
                class="team-pick-btn w-full flex items-center gap-3 px-4 py-3 transition-all duration-150 text-left ${colorClass}"
                data-action="click->bracket#pickWinner"
                data-bracket-game-id-param="${finalGameId}"
                data-bracket-winner-id-param="${teamId}"
                data-bracket-conference-param="${conference}"
                data-bracket-game-type-param="final"
                data-bracket-home-away-param="${slotType}">
          <span class="text-xs font-bold text-gray-400 w-4">#${teamSeed}</span>
          <span class="font-semibold text-sm">${teamName}</span>
          <span class="text-xs text-gray-500 ml-1">${labelText}</span>
          ${checkmark}
        </button>`
    }

    const makePlaceholder = (label) => `
      <div class="w-full flex items-center gap-3 px-4 py-3 bg-gray-800 opacity-50">
        <span class="text-xs font-bold text-gray-500 w-4">?</span>
        <span class="text-sm text-gray-500 italic">${label}</span>
      </div>`

    const homeSlot = homeTeamId
      ? makeTeamBtn(homeTeamId, homeTeamSeed, homeTeamName, "(loser of #7v8)", "home")
      : makePlaceholder("Loser of #7 vs #8")

    const awaySlot = awayTeamId
      ? makeTeamBtn(awayTeamId, awayTeamSeed, awayTeamName, "(winner of #9v10)", "away")
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
