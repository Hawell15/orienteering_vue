<template>
    <div class="show-page">
        <div class="hero">
            <TopoBackdrop />
            <div class="hero-inner">
                <div class="hero-top">
                    <div>
                        <div class="eyebrow">👤 Sportiv</div>
                        <h1 class="title">{{ runner.runner_name }} {{ runner.surname }}</h1>
                        <div class="subtitle">
                            <span v-if="runner.yob">{{ runner.yob }}</span>
                            <template v-if="runner.gender">
                                <span class="dot">·</span>
                                <span>{{ runner.gender }}</span>
                            </template>
                            <template v-if="runner.club">
                                <span class="dot">·</span>
                                <span>
                                    <a :href="`/clubs/${runner.club_id}`">{{ runner.club.club_name }}</a>
                                </span>
                            </template>
                        </div>
                        <div class="badges">
                            <span class="badge-pill">FOS #{{ runner.id }}</span>
                            <span v-if="runner.best_category" class="badge-pill ecn">Titlu: {{ runner.best_category.category_name }}</span>
                            <span v-if="runner.wre_id" class="badge-pill wre">
                                <a :href="`https://ranking.orienteering.org/PersonView?person=${runner.wre_id}`">WRE #{{ runner.wre_id }}</a>
                            </span>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="stat-cards">
            <div class="stat-card">
                <div class="stat-icon">🎖</div>
                <div class="stat-label">Titlul</div>
                <div class="stat-value">
                    <a v-if="runner.best_category" :href="`/categories/${runner.best_category_id}`">{{ runner.best_category.category_name }}</a>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">⭐</div>
                <div class="stat-label">Categoria actuală</div>
                <div class="stat-value">
                    <a v-if="runner.category" :href="`/categories/${runner.category_id}`">{{ runner.category.category_name }}</a>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">📅</div>
                <div class="stat-label">Valabilă până</div>
                <div class="stat-value">{{ runner.category_valid || '—' }}</div>
            </div>
            <div class="stat-card accent" v-if="runner.wre_id">
                <div class="stat-icon">🌍</div>
                <div class="stat-label">WRE</div>
                <div class="stat-value">
                    <a :href="`https://ranking.orienteering.org/PersonView?person=${runner.wre_id}`">#{{ runner.wre_id }}</a>
                </div>
            </div>
        </div>

        <div class="section" v-if="runner.wre_id">
            <div class="section-card">
                <div class="section-card-title">🌍 WRE Ranking</div>
                <div class="info-grid">
                    <div class="info-row">
                        <span class="label">Sprint (Loc / Puncte)</span>
                        <span class="value">{{ runner.sprint_wre_place || '—' }} / {{ runner.sprint_wre_rang || '—' }}</span>
                    </div>
                    <div class="info-row">
                        <span class="label">Pădure (Loc / Puncte)</span>
                        <span class="value">{{ runner.forest_wre_place || '—' }} / {{ runner.forest_wre_rang || '—' }}</span>
                    </div>
                </div>
            </div>
        </div>

        <div v-if="isAdmin" class="section">
            <div class="section-card">
                <div class="section-card-title">🔀 Unește cu un alt sportiv</div>
                <div class="merge-card">
                    <label for="runner_id" class="merge-label">Sportiv duplicat cu:</label>
                    <select id="runner_id" v-model="selectedRunner" class="form-select form-select-sm">
                        <option v-for="r in runnersData" :key="r.id" :value="r.id">{{ r.runner_name }} {{ r.surname }}</option>
                    </select>
                    <div class="form-check">
                        <input id="main_runner_check" v-model="mainRunner" type="checkbox" class="form-check-input" checked />
                        <label class="form-check-label" for="main_runner_check">Păstrează acesta</label>
                    </div>
                    <button class="btn btn-sm btn-success" @click="openMergeModal">Salvează</button>
                </div>
            </div>
        </div>

        <div class="section">
            <button class="section-toggle" type="button" data-bs-toggle="collapse" data-bs-target="#membershipsTable" aria-expanded="false" aria-controls="membershipsTable">
                <span class="section-icon">🪪</span>
                <span class="section-title">Afilieri</span>
                <span class="section-meta">{{ memberships.length }}</span>
                <span class="section-caret">▾</span>
            </button>
            <div class="collapse" id="membershipsTable">
                <div class="section-body">
                    <MembershipsTable :elements="memberships" @order="orderMembershipTable"></MembershipsTable>
                </div>
            </div>
        </div>

        <div class="section">
            <button class="section-toggle" type="button" data-bs-toggle="collapse" data-bs-target="#confirmationsTable" aria-expanded="false" aria-controls="confirmationsTable">
                <span class="section-icon">📜</span>
                <span class="section-title">Istoria îndeplinirilor</span>
                <span class="section-meta">{{ confirmationResults.length }}</span>
                <span class="section-caret">▾</span>
            </button>
            <div class="collapse" id="confirmationsTable">
                <div class="section-body">
                    <table class="table table-striped table-hover">
                        <thead class="table-light">
                            <tr>
                                <th>Data</th>
                                <th>Categoria îndeplinită</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="(element, index) in confirmationResults" :key="element.id"
                                :class="{ newConfirmation: element.result_category_name !== confirmationResults[index + 1]?.result_category_name }">
                                <td>{{ element.date }}</td>
                                <td>{{ element.result_category_name }}</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <div class="section">
            <button class="section-toggle" type="button" data-bs-toggle="collapse" data-bs-target="#resultsTable" aria-expanded="false" aria-controls="resultsTable">
                <span class="section-icon">🏅</span>
                <span class="section-title">Rezultate</span>
                <span class="section-meta">{{ results.length }}</span>
                <span class="section-caret">▾</span>
            </button>
            <div class="collapse" id="resultsTable">
                <div class="section-body">
                    <ResultsTable :elements="results" :hidden-columns="['full_name']" @order="orderResultTable"></ResultsTable>
                </div>
            </div>
        </div>

        <div class="section" v-if="relayParticipations.length">
            <button class="section-toggle" type="button" data-bs-toggle="collapse" data-bs-target="#relaysTable" aria-expanded="false" aria-controls="relaysTable">
                <span class="section-icon">🔁</span>
                <span class="section-title">Ștafete</span>
                <span class="section-meta">{{ relayParticipations.length }}</span>
                <span class="section-caret">▾</span>
            </button>
            <div class="collapse" id="relaysTable">
                <div class="section-body">
                    <RelayParticipationsTable :elements="relayParticipations" />
                </div>
            </div>
        </div>

        <div class="footer-actions">
            <button class="btn btn-outline-secondary" @click="goBack">← Înapoi</button>
            <div v-if="isAdmin" class="action-group">
                <button class="btn btn-success btn-sm" @click="editElement(runner)">Editează</button>
                <button class="btn btn-danger btn-sm" @click="deleteRunner(runner.id)">Șterge</button>
            </div>
        </div>

        <Modal ref="modal" :runner="modalElement" :isNew="false" @save="updateElement" />
        <MergeModal ref="mergeModal" @save="handleMergeSave" />
    </div>
</template>
<script setup>
import { ref, onMounted } from 'vue'
import axios from '@/axios'
import Modal from './Modal.vue'
import MergeModal from './MergeModal.vue'
import MembershipsTable from '../Membership/Table.vue'
import ResultsTable from '../Result/Table.vue'
import RelayParticipationsTable from './RelayParticipationsTable.vue'
import TopoBackdrop from '../shared/TopoBackdrop.vue'
import { isAdmin } from '@/currentUser'

const runner = ref({})
const runnerId = ref("")
const results = ref([])
const relayParticipations = ref([])

const resultSorting = ref({
    "sorting[sort_by]": "date",
    "sorting[direction]": "desc"
})

const confirmationResults = ref([])

const memberships = ref([])

const membershipSorting = ref({
    "sorting[sort_by]": "id",
    "sorting[direction]": "asc"
})

const modalElement = ref({})
const modal = ref(null)

const runnersData = ref([])
const selectedRunner = ref(null)
const mainRunner = ref(true)
const mergeModal = ref(null)

onMounted(() => {
    runnerId.value = window.location.pathname.split('/').pop();
    getData();
    getConfirmationResults();
    getResults();
    getMemberships();
    getRunners();
    getRelayParticipations();
})

async function getRelayParticipations() {
    const res = await axios.get(`/runners/${runnerId.value}/relays.json`)
    relayParticipations.value = res.data || []
}

async function getRunners() {
    const res = await axios.get('/runners.json', { params: { "sorting[sort_by]": "runner_name", "sorting[direction]": "asc" } })
    runnersData.value = res.data
}

async function openMergeModal() {
    if (!selectedRunner.value) return

    const currentId = parseInt(runnerId.value, 10)
    const otherId   = selectedRunner.value

    const mainId   = mainRunner.value ? currentId : otherId
    const mergedId = mainRunner.value ? otherId   : currentId

    const [ main, merged ] = await Promise.all([
        axios.get(`/runners/${mainId}.json`).then(r => r.data),
        axios.get(`/runners/${mergedId}.json`).then(r => r.data)
    ])

    mergeModal.value.show(main, merged)
}

async function handleMergeSave(payload) {
    const attributes = {}
    Object.entries(payload.selections).forEach(([ key, source ]) => {
        if (source === 'merged') {
            attributes[key] = payload.mergedRunner[key]
        } else if (source === 'other') {
            attributes[key] = payload.otherValues[key]
        }
    })

    const body = { merged_runner_id: payload.mergedRunner.id }
    if (Object.keys(attributes).length > 0) {
        body.runner = attributes
    }

    await axios.post(`/runners/${payload.mainRunner.id}/merge_runners`, body)

    window.location = `/runners/${payload.mainRunner.id}`
}

async function getData() {
    const res = await axios.get(`/runners/${runnerId.value}.json`)
    runner.value = res.data;
}

async function getResults() {
    resultSorting.value["runner"] = runnerId.value
    const res = await axios.get('/results.json', { params: resultSorting.value })
    results.value = res.data;
}

async function getMemberships() {
    membershipSorting.value["runner"] = runnerId.value
    const res = await axios.get('/memberships.json', { params: membershipSorting.value })
    memberships.value = res.data;
}

async function getConfirmationResults() {
    const params = {
        "sorting[sort_by]": "date",
        "sorting[direction]": "desc",
        "runner": runnerId.value,
        "status": ["confirmed"]
    }

    const res = await axios.get('/results.json', { params: params })
    confirmationResults.value = res.data;
}

function orderResultTable(sortKey) {
    orderTable(sortKey, resultSorting)
    getResults();
}

function orderMembershipTable(sortKey) {
    orderTable(sortKey, membershipSorting)
    getMemberships();
}

function orderTable(sortKey, filters) {
    const isCurrentSort = filters.value["sorting[sort_by]"] === sortKey;
    const currentDir = filters.value["sorting[direction]"];

    filters.value["sorting[direction]"] = (isCurrentSort && currentDir === "asc") ? "desc" : "asc";
    filters.value["sorting[sort_by]"] = sortKey;
}

function editElement(runner) {
    modalElement.value = { ...runner }
    modal.value.show()
}

function updateElement(runnerData, done) {
    axios.patch(`/runners/${runnerData.id}.json`, { runner: runnerData }).then(() => {
        getData();
        done()
    })
}

function deleteRunner(id) {
    if (confirm('Esti sigur ca vrei sa stergi aceast sportiv?')) {
        axios.delete(`/runners/${id}`).then(() => {
            window.location = document.referrer || "/runners"
        })
    }
}

function goBack() {
    window.location = document.referrer || "/runners"
}
</script>

<style scoped src="../shared/show.css"></style>

<style scoped>
.newConfirmation td {
    background-color: #dcfce7 !important;
}
</style>
