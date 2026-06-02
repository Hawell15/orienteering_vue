<template>
    <div class="show-page">
        <div class="hero">
            <TopoBackdrop />
            <div class="hero-inner">
                <div class="hero-top">
                    <div>
                        <div class="eyebrow">🧭 Competiție de orientare</div>
                        <h1 class="title">{{ competition.competition_name }}</h1>
                        <div class="subtitle">
                            <span>{{ competition.distance_type }}</span>
                            <span class="dot">·</span>
                            <span>{{ competition.location }}, {{ competition.country }}</span>
                            <span class="dot">·</span>
                            <span>{{ competition.date }}</span>
                        </div>
                        <div class="badges">
                            <span v-if="competition.ecn" class="badge-pill ecn">● ECN</span>
                            <span v-if="competition.wre_id" class="badge-pill wre">
                                <a :href="`http://ranking.orienteering.sport/ResultsView?event=${competition.wre_id}`">● WRE #{{ competition.wre_id }}</a>
                            </span>
                        </div>
                    </div>
                    <div class="hero-actions">
                        <div class="dropdown">
                            <button class="btn btn-light dropdown-toggle" type="button" data-bs-toggle="dropdown">📄 PDF</button>
                            <ul class="dropdown-menu">
                                <li><a class="dropdown-item" :href="`/competitions/${competitionId}.pdf`">Clasic</a></li>
                                <li><a class="dropdown-item" :href="`/competitions/${competitionId}.pdf?style=modern`">Modern</a></li>
                                <li><a class="dropdown-item" :href="`/competitions/${competitionId}.pdf?style=minimal`">Minimal</a></li>
                                <li><hr class="dropdown-divider"></li>
                                <li><a class="dropdown-item" :href="`/competitions/${competitionId}/confirmations`">📜 Confirmări categorii (online)</a></li>
                                <li><a class="dropdown-item" :href="`/competitions/${competitionId}.pdf?style=confirmations`">📜 Confirmări categorii (PDF)</a></li>
                            </ul>
                        </div>
                        <button v-if="isAdmin" class="btn btn-success" @click="openResultModal">+ Rezultat</button>
                        <div v-if="isAdmin" class="dropdown">
                            <button class="btn btn-outline-light dropdown-toggle" type="button" data-bs-toggle="dropdown">Acțiuni</button>
                            <ul class="dropdown-menu">
                                <li><button class="dropdown-item" @click="toggleEcn">{{ competition.ecn ? 'Exclude din ECN' : 'Adauga la ECN' }}</button></li>
                                <li v-if="competition.ecn"><button class="dropdown-item" @click="openEcnModal">Seteaza Coeficientii Grupelor</button></li>
                                <li><button class="dropdown-item" @click="openClasaModal">Seteaza Clasele Grupelor</button></li>
                                <li v-if="competition.ecn"><a class="dropdown-item" :href="`/competitions/${competitionId}/new_runners`">Sportivi noi</a></li>
                                <li><button class="dropdown-item" :disabled="sendingTelegram" @click="sendTelegramResults">{{ sendingTelegram ? '⏳ Se trimite…' : '📨 Trimite rezultate pe Telegram' }}</button></li>
                                <li><hr class="dropdown-divider"></li>
                                <li><button class="dropdown-item" @click="editElement(competition)">Editeaza</button></li>
                                <li><button class="dropdown-item text-danger" @click="deleteCompetition(competition.id)">Sterge</button></li>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="stat-cards">
            <div class="stat-card">
                <div class="stat-icon">📅</div>
                <div class="stat-label">Data</div>
                <div class="stat-value">{{ competition.date }}</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">🏃</div>
                <div class="stat-label">Tipul distanței</div>
                <div class="stat-value">{{ competition.distance_type }}</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">📍</div>
                <div class="stat-label">Locul</div>
                <div class="stat-value">{{ competition.location }}</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">⭐</div>
                <div class="stat-label">ECN</div>
                <div class="stat-value">{{ competition.ecn ? 'Da' : 'Nu' }}</div>
            </div>
        </div>

        <div class="section">
            <div class="group-pills">
                <button v-for="g in groups" :key="g.id" class="group-pill"
                    :class="{ active: activeGroup?.id === g.id }" @click="selectGroup(g)">
                    {{ g.group_name }}
                </button>
            </div>
        </div>

        <div v-if="activeGroup" class="section">
            <div class="group-meta">
                <div>
                    <div class="group-title">{{ activeGroup.group_name }}</div>
                    <div class="group-sub">
                        <span>Rang: <b>{{ activeGroup.group_rang || '—' }}</b></span>
                        <span class="dot">·</span>
                        <span>Clasa: <b>{{ formatGroupClasa(activeGroup.group_clasa) || '—' }}</b></span>
                    </div>
                </div>
            </div>

            <div v-if="!competition.relay && podium.length" class="podium">
                <div v-for="(p, i) in podium" :key="p.id" class="podium-card" :class="`place-${i + 1}`">
                    <div class="medal">{{ ['🥇', '🥈', '🥉'][i] }}</div>
                    <div class="podium-name"><a :href="`/runners/${p.runner_id}`">{{ p.full_name }}</a></div>
                    <div class="podium-club"><a :href="`/clubs/${p.club_id}`">{{ p.club_name }}</a></div>
                    <div class="podium-time">{{ formatResultTime(p.time) }}</div>
                </div>
            </div>

            <div v-if="competition.relay && relayPodium.length" class="podium">
                <div v-for="(r, i) in relayPodium" :key="r.id" class="podium-card" :class="`place-${i + 1}`">
                    <div class="medal">{{ ['🥇', '🥈', '🥉'][i] }}</div>
                    <div class="podium-name">{{ r.team }}</div>
                    <div class="podium-club">{{ r.category_name || 'f/c' }}</div>
                    <div class="podium-time">{{ formatResultTime(r.time) }}</div>
                </div>
            </div>

            <div class="results-card">
                <RelayResultsTable v-if="competition.relay"
                                   :elements="activeGroup.relay_results || []"
                                   @edit="editRelayResult"
                                   @delete="deleteRelayResult"
                                   @reorder="reorderRelayLegs" />
                <ResultsTable v-else
                              :elements="activeGroup.results"
                              :hidden-columns="['competition_name', 'group_name']"
                              @refresh="getResults" />
            </div>

            <div v-if="isAdmin" class="results-toolbar">
                <button v-if="competition.relay" class="btn btn-sm btn-success" @click="openRelayCreate">+ Ștafetă</button>
                <button class="btn btn-sm btn-outline-success" :disabled="countingRang" @click="countRang(activeGroup)">
                    {{ countingRang ? '⏳ Se recalculează…' : '🔄 Recalculează rangul' }}
                </button>
            </div>

            <div v-if="activeGroup.category_percentages?.length" class="percentages">
                <div class="percentages-title">Procente pe categorii</div>
                <div class="percentages-grid">
                    <div v-for="row in activeGroup.category_percentages" :key="row.category" class="percent-row">
                        <span class="cat">{{ row.category }}</span>
                        <span class="pct">{{ row.percent }}</span>
                        <span class="t">{{ row.time }}</span>
                    </div>
                </div>
            </div>
        </div>

        <div class="footer-actions">
            <button class="btn btn-outline-secondary" @click="goBack">← Înapoi</button>
        </div>

        <Modal ref="modal" :competition="modalElement" :isNew="false" @save="updateElement" />
        <EcnCoeficients ref="ecnModal" :competitionId="competitionId" @save="getResults" />
        <GroupClasa ref="clasaModal" :competitionId="competitionId" @save="" />
        <ResultCreate ref="resultCreate" @save="getResults" />
        <RelayResultCreate ref="relayCreate" @save="getResults" />
    </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import axios from '@/axios'
import Modal from './Modal.vue'
import EcnCoeficients from './EcnCoeficients.vue'
import GroupClasa from './GroupClasa.vue'
import ResultCreate from '../Result/Create.vue'
import ResultsTable from '../Result/Table.vue'
import RelayResultCreate from '../RelayResult/Create.vue'
import RelayResultsTable from '../RelayResult/Table.vue'
import TopoBackdrop from '../shared/TopoBackdrop.vue'
import { isAdmin } from '@/currentUser'

const competition = ref({})
const competitionId = ref("")
const modalElement = ref({})
const modal = ref(null)
const ecnModal = ref(null)
const clasaModal = ref(null)
const resultCreate = ref(null)
const relayCreate = ref(null)

const groups = ref([])
const activeGroup = ref(null)
const groupDetailsCache = new Map()
const countingRang = ref(false)
const sendingTelegram = ref(false)

const podium = computed(() => (activeGroup.value?.results || []).slice(0, 3))
const relayPodium = computed(() =>
    (activeGroup.value?.relay_results || [])
        .filter(r => r.place && r.place > 0)
        .slice(0, 3)
)

onMounted(async () => {
    competitionId.value = window.location.pathname.split('/').pop()
    await getData()
    getResults()
})

async function getData() {
    const res = await axios.get(`/competitions/${competitionId.value}.json`)
    competition.value = res.data
}

async function toggleEcn() {
    const res = await axios.patch(`/competitions/${competitionId.value}.json`, {
        competition: { ecn: !competition.value.ecn }
    })
    competition.value = res.data
}

async function getResults() {
    if (competition.value.relay) {
        await getRelayResults()
    } else {
        await getRegularResults()
    }
    selectGroupFromHash()
}

async function getRegularResults() {
    const params = {
        "competition": competitionId.value,
        "sorting[sort_by]": "place",
        "sorting[direction]": "asc"
    }
    const res = await axios.get('/results.json', { params })
    groups.value = Object.values(convertResultsFormat(res.data))
        .sort((a, b) => a.group_name.localeCompare(b.group_name, undefined, { numeric: true, sensitivity: 'base' }))
}

async function getRelayResults() {
    const params = {
        "competition": competitionId.value,
        "sorting[sort_by]": "place",
        "sorting[direction]": "asc"
    }
    const res = await axios.get('/relay_results.json', { params })
    groups.value = Object.values(convertRelayResultsFormat(res.data))
        .sort((a, b) => a.group_name.localeCompare(b.group_name, undefined, { numeric: true, sensitivity: 'base' }))
}

function convertResultsFormat(results) {
    const groupsMap = {}
    results.forEach(r => {
        if (!groupsMap[r.group_id]) {
            groupsMap[r.group_id] = {
                id: r.group_id,
                group_name: r.group_name,
                group_rang: r.group_rang,
                group_clasa: r.group_clasa,
                results: []
            }
        }
        groupsMap[r.group_id].results.push(r)
    })
    return groupsMap
}

function convertRelayResultsFormat(relays) {
    const groupsMap = {}
    relays.forEach(r => {
        if (!groupsMap[r.group_id]) {
            groupsMap[r.group_id] = {
                id: r.group_id,
                group_name: r.group_name,
                group_rang: r.group_rang,
                group_clasa: r.group_clasa,
                relay_results: []
            }
        }
        groupsMap[r.group_id].relay_results.push(r)
    })
    return groupsMap
}

async function selectGroup(group) {
    if (!group) return
    activeGroup.value = group
    window.location.hash = group.group_name
    await loadGroupDetails(group)
    console.log(activeGroup.value.rang);
}

async function loadGroupDetails(group) {
    if (groupDetailsCache.has(group.id)) {
        group.category_percentages = groupDetailsCache.get(group.id)
        return
    }
    const res = await axios.get(`/groups/${group.id}.json`)
    const percentages = res.data.category_percentages || []
    groupDetailsCache.set(group.id, percentages)
    group.category_percentages = percentages
}

async function countRang(group) {
    if (!group) return
    if (!confirm(`Recalculează rangul și categoriile pentru grupa "${group.group_name}"?`)) return
    countingRang.value = true
    try {
        await axios.post(`/groups/${group.id}/count_rang.json`)
        groupDetailsCache.delete(group.id)
        await getResults()
    } finally {
        countingRang.value = false
    }
}

function selectGroupFromHash() {
    if (groups.value.length === 0) return
    const hash = window.location.hash.replace("#", "")
    if (!hash) {
        selectGroup(groups.value[0])
        return
    }
    const found = groups.value.find(g => g.group_name === hash)
    selectGroup(found || groups.value[0])
}

function formatGroupClasa(clasa) {
    const map = { "2": "MSRM", "3": "CMSRM", "4": "I", "5": "II", "7": "I j", "10": "f/c" }
    return map[clasa]
}

function formatResultTime(seconds) {
    if (seconds == null) return ''
    const h = Math.floor(seconds / 3600)
    const m = Math.floor((seconds % 3600) / 60)
    const s = seconds % 60
    return String(h).padStart(2, '0') + ':' + String(m).padStart(2, '0') + ':' + String(s).padStart(2, '0')
}

function openEcnModal() { ecnModal.value.show() }
function openClasaModal() { clasaModal.value.show() }
function openResultModal() {
    resultCreate.value.createNew({
        competition_id: Number(competitionId.value),
        group_id: activeGroup.value?.id
    })
}

function openRelayCreate() {
    relayCreate.value.createNew({
        competition_id: Number(competitionId.value),
        group_id: activeGroup.value?.id,
        date: competition.value.date
    })
}

function editRelayResult(relay) {
    relayCreate.value.editExisting(relay)
}

async function deleteRelayResult(relay) {
    if (!confirm(`Ștergi ștafeta "${relay.team}"?`)) return
    await axios.delete(`/relay_results/${relay.id}.json`)
    await getResults()
}

async function reorderRelayLegs(relay, newResultsId) {
    await axios.patch(`/relay_results/${relay.id}.json`, { relay_result: { results_id: newResultsId } })
    await getResults()
}

async function sendTelegramResults() {
    if (!confirm('Trimite rezultatele confirmate și plafonate pe canalul Telegram?')) return
    sendingTelegram.value = true
    try {
        const res = await axios.post(`/competitions/${competitionId.value}/telegram_results.json`)
        if (res.data.sent > 0) {
            alert(`S-au trimis ${res.data.sent} mesaje pe Telegram.`)
        } else if (res.data.error) {
            alert(`Trimiterea a eșuat: ${res.data.error}`)
        } else {
            alert('Nu există rezultate confirmate sau plafonate pentru această competiție.')
        }
    } catch (e) {
        alert(`Trimiterea a eșuat: ${e.response?.data?.error || e.message}`)
    } finally {
        sendingTelegram.value = false
    }
}

function editElement(comp) {
    modalElement.value = { ...comp }
    modal.value.show()
}

function updateElement(competitionData, done) {
    axios.patch(`/competitions/${competitionData.id}.json`, { competition: competitionData }).then(res => {
        competition.value = res.data
        done()
    })
}

function deleteCompetition(id) {
    if (confirm('Esti sigur ca vrei sa stergi această competiție?')) {
        axios.delete(`/competitions/${id}`).then(() => {
            window.location = document.referrer || "/competitions"
        })
    }
}

function goBack() {
    window.location = document.referrer || "/competitions"
}
</script>

<style scoped src="../shared/show.css"></style>
