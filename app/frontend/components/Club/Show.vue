<template>
    <div class="show-page">
        <div class="hero">
            <TopoBackdrop />
            <div class="hero-inner">
                <div class="hero-top">
                    <div>
                        <div class="eyebrow">🏛 Club de orientare</div>
                        <h1 class="title">{{ club.club_name }}</h1>
                        <div class="subtitle">
                            <span v-if="club.territory">{{ club.territory }}</span>
                            <template v-if="club.representative">
                                <span class="dot">·</span>
                                <span>{{ club.representative }}</span>
                            </template>
                        </div>
                        <div class="badges" v-if="club.alternative_club_names?.length">
                            <span v-for="name in club.alternative_club_names" :key="name" class="badge-pill">{{ name }}</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="stat-cards">
            <div class="stat-card">
                <div class="stat-icon">📧</div>
                <div class="stat-label">Email</div>
                <div class="stat-value">{{ club.email || '—' }}</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">📞</div>
                <div class="stat-label">Telefon</div>
                <div class="stat-value">{{ club.phone || '—' }}</div>
            </div>
            <div class="stat-card accent">
                <div class="stat-icon">🏃</div>
                <div class="stat-label">Sportivi</div>
                <div class="stat-value"><a :href="`/runners?club=${club.id}`">{{ runners.length }}</a></div>
            </div>
            <div class="stat-card accent">
                <div class="stat-icon">🏅</div>
                <div class="stat-label">Rezultate</div>
                <div class="stat-value"><a :href="`/results?club=${club.id}`">{{ results.length }}</a></div>
            </div>
        </div>

        <div v-if="isAdmin" class="section">
            <div class="section-card">
                <div class="section-card-title">🔀 Unește cu un alt club</div>
                <div class="merge-card">
                    <label for="club_id" class="merge-label">Club duplicat cu:</label>
                    <select id="club_id" v-model="selectedClub" class="form-select form-select-sm">
                        <option v-for="c in clubsData" :key="c.id" :value="c.id">{{ c.club_name }}</option>
                    </select>
                    <div class="form-check">
                        <input id="main_club_check" v-model="mainClub" type="checkbox" class="form-check-input" checked />
                        <label class="form-check-label" for="main_club_check">Păstrează acesta</label>
                    </div>
                    <button class="btn btn-sm btn-success" @click="mergeClub">Salvează</button>
                </div>
            </div>
        </div>

        <div class="section">
            <button class="section-toggle" type="button" data-bs-toggle="collapse" data-bs-target="#runnersTable" aria-expanded="false" aria-controls="runnersTable">
                <span class="section-icon">👥</span>
                <span class="section-title">Sportivi</span>
                <span class="section-meta">{{ runners.length }}</span>
                <span class="section-caret">▾</span>
            </button>
            <div class="collapse" id="runnersTable">
                <div class="section-body">
                    <RunnersTable :elements="runners" @order="orderRunnerTable"></RunnersTable>
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
                    <ResultsTable :elements="results" :hidden-columns="['club_name']" @order="orderResultTable"></ResultsTable>
                </div>
            </div>
        </div>

        <div class="footer-actions">
            <button class="btn btn-outline-secondary" @click="goBack">← Înapoi</button>
            <div v-if="isAdmin" class="action-group">
                <button class="btn btn-success btn-sm" @click="editElement(club)">Editează</button>
                <button class="btn btn-danger btn-sm" @click="deleteClub(club.id)">Șterge</button>
            </div>
        </div>

        <Modal ref="modal" :club="modalElement" :isNew="false" @save="updateElement" />
    </div>
</template>
<script setup>
import { ref, onMounted } from 'vue'
import axios from '@/axios'
import Modal from './Modal.vue'
import RunnersTable from '../Runner/Table.vue'
import ResultsTable from '../Result/Table.vue'
import TopoBackdrop from '../shared/TopoBackdrop.vue'
import { isAdmin } from '@/currentUser'

const club = ref({})
const modalElement = ref({})
const modal = ref(null)
const runners = ref([])
const results = ref([])
const clubId = ref("")
const runnerSorting = ref({
    "sorting[sort_by]": "id",
    "sorting[direction]": "asc"
})
const resultSorting = ref({
    "sorting[sort_by]": "date",
    "sorting[direction]": "desc"
})

const clubsSorting = ref({
    "sorting[sort_by]": "club_name",
    "sorting[direction]": "asc"
})

const clubsData = ref([])
const mainClub = ref(true)
const selectedClub = ref({})
onMounted(() => {
    clubId.value = window.location.pathname.split('/').pop();
    getData();
    getRunners();
    getResults();
    getClubs();
})

async function getData() {
    const res = await axios.get(`/clubs/${clubId.value}.json`)
    club.value = res.data;
}

async function getRunners() {
    runnerSorting.value["club"] = clubId.value
    const res = await axios.get('/runners.json', { params: runnerSorting.value })
    runners.value = res.data;
}

async function getResults() {
    resultSorting.value["club"] = clubId.value
    const res = await axios.get('/results.json', { params: resultSorting.value })
    results.value = res.data;
}

function orderRunnerTable(sortKey) {
    orderTable(sortKey, runnerSorting)
    getRunners()
}

function orderResultTable(sortKey) {
    orderTable(sortKey, resultSorting)
    getResults()
}

function orderTable(sortKey, filters) {
    const isCurrentSort = filters.value["sorting[sort_by]"] === sortKey;
    const currentDir = filters.value["sorting[direction]"];

    filters.value["sorting[direction]"] = (isCurrentSort && currentDir === "asc") ? "desc" : "asc";
    filters.value["sorting[sort_by]"] = sortKey;
}

function editElement(club) {
    modalElement.value = { ...club }
    modal.value.show()
}

function updateElement(clubData, done) {
    axios.patch(`/clubs/${clubData.id}.json`, { club: clubData }).then(res => {
        club.value = res.data
        done()
    })
}

function deleteClub(id) {
    if (confirm('Esti sigur ca vrei sa stergi aceast club?')) {
        axios.delete(`/clubs/${id}`).then(() => {
            window.location = document.referrer || "/clubs"
        })
    }
}

function goBack() {
    window.location = document.referrer || "/clubs"
}

async function getClubs() {
    const res = await axios.get('/clubs.json', { params: clubsSorting.value })
    clubsData.value = res.data;
}

function mergeClub() {
    let mainId = null;
    let mergedId = null;

    mainId = mainClub.value ? clubId.value : selectedClub.value
    mergedId = mainClub.value ? selectedClub.value : clubId.value

    axios.post(`/clubs/merge_clubs/${mainId}`, {merged_club_id: mergedId})

    window.location = `/clubs/${mainId}`;
}
</script>

<style scoped src="../shared/show.css"></style>
