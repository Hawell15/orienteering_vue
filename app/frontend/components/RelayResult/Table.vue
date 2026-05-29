<template>
    <div class="relay-table">
        <div v-for="relay in elements" :key="relay.id" class="relay-card">
            <div class="relay-header">
                <div class="relay-place">{{ relay.place || '—' }}</div>
                <div class="relay-team">
                    <div class="relay-team-name">{{ relay.team }}</div>
                    <div class="relay-meta">{{ relay.category_name || 'f/c' }}</div>
                </div>
                <div class="relay-time">{{ formatTime(relay.time) }}</div>
                <div v-if="isAdmin" class="relay-actions">
                    <template v-if="reorderingId === relay.id">
                        <button class="btn btn-sm btn-success" @click="saveReorder(relay)">Salvează ordinea</button>
                        <button class="btn btn-sm btn-outline-secondary" @click="cancelReorder">Anulează</button>
                    </template>
                    <template v-else>
                        <button class="btn btn-sm btn-outline-primary" @click="startReorder(relay)">Reordonează</button>
                        <button class="btn btn-sm btn-outline-success" @click="$emit('edit', relay)">Editează</button>
                        <button class="btn btn-sm btn-outline-danger" @click="$emit('delete', relay)">Șterge</button>
                    </template>
                </div>
            </div>
            <table class="legs-table">
                <thead>
                    <tr>
                        <th>Etapa</th>
                        <th v-if="reorderingId === relay.id" class="reorder-col">Ordine</th>
                        <th>Sportiv</th>
                        <th>Categoria curentă</th>
                        <th>Timpul etapei</th>
                        <th>Timpul cumulat</th>
                        <th>Categoria îndeplinită</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="(leg, i) in legsFor(relay)" :key="leg.id">
                        <td>{{ i + 1 }}</td>
                        <td v-if="reorderingId === relay.id" class="reorder-col">
                            <button class="btn btn-sm btn-light arrow-btn" :disabled="i === 0" @click="moveUp(i)" title="Sus">↑</button>
                            <button class="btn btn-sm btn-light arrow-btn" :disabled="i === legsFor(relay).length - 1" @click="moveDown(i)" title="Jos">↓</button>
                        </td>
                        <td>
                            <a v-if="leg.runner_id" :href="`/runners/${leg.runner_id}`">{{ leg.full_name }}</a>
                            <span v-else>—</span>
                        </td>
                        <td>{{ leg.runner_category_name || 'f/c' }}</td>
                        <td>{{ formatTime(leg.time) }}</td>
                        <td>{{ formatTime(cumulativeTime(legsFor(relay), i)) }}</td>
                        <td>{{ leg.leg_category_name || 'f/c' }}</td>
                    </tr>
                    <tr v-if="!relay.legs.length">
                        <td :colspan="reorderingId === relay.id ? 7 : 6" class="empty-legs">Niciun rezultat de etapă atașat</td>
                    </tr>
                </tbody>
            </table>
        </div>
        <div v-if="!elements.length" class="empty-relays">Niciun rezultat de ștafetă în această grupă.</div>
    </div>
</template>

<script setup>
import { ref } from 'vue'
import { isAdmin } from '@/currentUser'

const props = defineProps({
    elements: { type: Array, default: () => [] }
})
const emit = defineEmits([ 'edit', 'delete', 'reorder' ])

const reorderingId = ref(null)
const editedLegs   = ref([])

function startReorder(relay) {
    reorderingId.value = relay.id
    editedLegs.value   = [ ...(relay.legs || []) ]
}

function cancelReorder() {
    reorderingId.value = null
    editedLegs.value   = []
}

function moveUp(i) {
    if (i === 0) return
    const arr = editedLegs.value
    ;[ arr[i - 1], arr[i] ] = [ arr[i], arr[i - 1] ]
}

function moveDown(i) {
    const arr = editedLegs.value
    if (i === arr.length - 1) return
    ;[ arr[i + 1], arr[i] ] = [ arr[i], arr[i + 1] ]
}

function legsFor(relay) {
    return reorderingId.value === relay.id ? editedLegs.value : (relay.legs || [])
}

function saveReorder(relay) {
    const newOrder = editedLegs.value.map(l => l.id)
    const oldOrder = (relay.legs || []).map(l => l.id)
    if (JSON.stringify(newOrder) !== JSON.stringify(oldOrder)) {
        emit('reorder', relay, newOrder)
    }
    cancelReorder()
}

function formatTime(seconds) {
    if (seconds == null) return '—'
    const h = Math.floor(seconds / 3600)
    const m = Math.floor((seconds % 3600) / 60)
    const s = seconds % 60
    return String(h).padStart(2, '0') + ':' + String(m).padStart(2, '0') + ':' + String(s).padStart(2, '0')
}

function cumulativeTime(legs, upTo) {
    let total = 0
    for (let i = 0; i <= upTo; i++) {
        total += (legs[i]?.time || 0)
    }
    return total
}
</script>

<style scoped>
.relay-card {
    background: white;
    border: 1px solid #d6e4d8;
    border-radius: 14px;
    margin-bottom: 1rem;
    overflow: hidden;
}
.relay-header {
    display: grid;
    grid-template-columns: 60px 1fr auto auto;
    align-items: center;
    gap: 1rem;
    padding: 0.8rem 1rem;
    background: linear-gradient(135deg, #f1f5e8, #e1ecd0);
    border-bottom: 1px solid #d6e4d8;
}
.relay-place { font-size: 1.6rem; font-weight: 800; color: #14532d; text-align: center; }
.relay-team-name { font-weight: 700; color: #14532d; font-size: 1.05rem; }
.relay-meta { color: #4f6b54; font-size: 0.85rem; }
.relay-time { font-variant-numeric: tabular-nums; font-weight: 700; font-size: 1.1rem; color: #14532d; }
.relay-actions { display: flex; gap: 0.4rem; flex-wrap: wrap; }
.legs-table { width: 100%; border-collapse: collapse; }
.legs-table th, .legs-table td { padding: 0.5rem 0.75rem; border-bottom: 1px solid #eef2eb; text-align: left; font-size: 0.9rem; }
.legs-table th { background: #f8faf5; color: #4f6b54; font-weight: 600; font-size: 0.78rem; text-transform: uppercase; letter-spacing: 0.5px; }
.legs-table td:nth-child(4), .legs-table td:nth-child(5) { font-variant-numeric: tabular-nums; }
.reorder-col { width: 80px; white-space: nowrap; }
.arrow-btn { padding: 0.1rem 0.45rem; font-size: 0.9rem; line-height: 1; }
.empty-legs, .empty-relays { color: #888; text-align: center; padding: 1rem; font-style: italic; }
</style>
